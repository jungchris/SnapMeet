//
//  MainViewController.m
//  ShareMySpot
//
//  Created by chris on 1/14/14.  Current App Store vers 1.0 - 04/07/2014.  See release and version notes at bottom of this document.
//  Copyright (c) 2014 Chris Jungmann. All rights reserved.
//
/*
Version 0.9 allows the iPhone user to share his location along with a snapshot of an event or place with a single recipient.  The recipient will receive a notification of the shared location and can view the map preview, snapshot and get directions to the event or place.  The recipient can then delete this snapshot and location, or keep it for up to 24 hours.  After 24 hours the location info and snapshot are automatically deleted.
 
 Version 1.0 First App Store version includes bug fixes identified in V0.9 beta testing with TestFlight, improved functionality, and robustness.  Unified user properties irregardless of type of login, and refactored methods used to manage internal user data.  Added method to provide user feedback when recipient does not yet have an account, and made changes to support future localization eforts.
 
 Version 1.1 First App Store upgrade redesigned interface with separate button on main screen for invoking Address Book Picker.  Added a 'Settings' screeen so user can check the app's permissions.  Added SMS and emailable links directly to App Store to allow app to be sent to friends.
*/

#import "MainViewController.h"

@interface MainViewController ()

@end

@implementation MainViewController

#pragma mark - View delegates

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"viewDidLoad");
    
    // locations counter
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.locationsCount = 0;
    
    // define the top nav button, and show it
    [self defineShareButton];
    [self.view addSubview:self.shareButton];
    
    // define and show the address book button
    [self defineAddressBookButton];
    [self.view addSubview:self.addressBookButton];
    
    // define the bottom nav button, but don't show it yet
    [self defineFriendsButton];
    [self.view addSubview:self.friendsButton];              // changed to show button with low alpga 6-24-14
    
    // define and show settings button
    [self defineSettingsButton];
    [self.view addSubview:self.settingsButton];
    
    // check the disk cache if the user is already logged in before invoking 'showLogin'
    self.currentUser = [PFUser currentUser];
    
    // on standard login c-rrentUser.username = chris@ipip.com and cUrrentUser.email = null so do additional 'if'
    if (self.currentUser) {
        
        // TODO: Get user's name
        NSLog(@" ---> [firstAndLast] %@", [self.currentUser objectForKey:@"firstAndLast"]);
        self.currentUserName = [self.currentUser objectForKey:@"firstAndLast"];
        
        // Get the user's facebook URL added 4-23-14
        NSDictionary *profileDict = [self.currentUser objectForKey:@"profile"];
        NSString *pictURL = [profileDict objectForKey:@"pictureURL"];
        NSLog(@" ---> [pictURL] %@", pictURL);
        self.currentUserURL = pictURL;

        // since retrieveUserInfoFromFB is asynchronous don't call rtrieveLocations if email is null
        if (self.currentUser.email == NULL) {
            // there is no email, we can assume this is a facebook user so let's request his/her info
            // retrieveUserInfoFromFB will make a call rtrieveLocations on succesful completion of async block
            [self retrieveUserInfoFromFB];
            
        } else {
            // There is an email address, assume non-facebook sign-in and retreive locations
            [self retrieveLocations:self.currentUser.email];
        
            // show who's logged in
            if (self.currentUserName) {
                
                NSMutableString *nameText = [[NSMutableString alloc] initWithCapacity:60];
                [nameText appendString:NSLocalizedStringWithDefaultValue(@"NAME_LABEL", nil, [NSBundle mainBundle], @"Logged in: ", nil)];
                [nameText appendString:self.currentUserName];
                self.nameLabel.text = nameText;
            }
            else if (self.currentUser.email) {
                
                NSMutableString *nameText = [[NSMutableString alloc] initWithCapacity:60];
                [nameText appendString:NSLocalizedStringWithDefaultValue(@"NAME_LABEL", nil, [NSBundle mainBundle], @"Logged in: ", nil)];
                [nameText appendString:self.currentUser.email];
                self.nameLabel.text = nameText;
            }
        }
        
    }
    else {
        // not logged in so let's show the login screen
        // TODO: Ensure it's Ok to allow user to use app without login
        [self performSegueWithIdentifier:@"showLogin" sender:self];
        
    }
    
    // activity indicator
    [_activityIndicator hidesWhenStopped];
    
    // this will add an observer for ddReceiveRemoteNotification method in AppDelegate.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remoteNotificationHandler) name:@"remoteNotification" object:nil];
    
    // this will add an observer for applcationDidEnterForeground method in AppDelegate.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterForegroundHandler) name:@"enterForeground" object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // Used this to debug view crash issue.  Resolved in shareLocationButton using class method.

    NSLog(@"viewWillAppear");
    
//    self.currentUser = [PFUser currentUser];
    
    // add iAd
    [self addADBannerViewToBottom];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    // Used this to debug view crash issue.  Resolved in shareLocationButton using class method.
    
    // clean up before removing this view
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}


#pragma mark - Custom Address book methods

// Workaround for the iPhone 4+4S crash on iOS 7.0.3 - 7.0.4
+ (ABPeoplePickerNavigationController *)sharedPeoplePicker {
    static ABPeoplePickerNavigationController *_sharedPicker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedPicker = [[ABPeoplePickerNavigationController alloc] init];
    });
    
    return _sharedPicker;
}

#pragma mark - Application delegates

// This is called by applicationWillEnterForeground (maybe I should use applicationDidBecomeActive instead?)
- (void)enterForegroundHandler {
    
//    self.currentUser = [PFUser currentUser];
    
    NSLog(@"self.currentUser.email: %@", self.currentUser.email);
    
    // update locations for standard user 3-14-14
    // removed && self.crrentFBUserEmail == NULL
    if (self.currentUser.email != NULL) {
        
        // this is a standard login user (not facebook)
        [self retrieveLocations:self.currentUser.email];
        
    }
    
    // update locations for facebook user 3-14-14
    // removed && self.crrentFBUserEmail != NULL
    if (self.currentUser.email == NULL) {
        
        // this is a facebook user
        [self retrieveUserInfoFromFB];
        
    }
}

// This is called by appdelegate didReceiveRemoteNotification on push notification reciept
- (void)remoteNotificationHandler {
    
    // first increment the appDelegate counter
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.locationsCount = appDelegate.locationsCount + 1;
    
    // update location for facebook user
    // removed && self.crrentFBUserEmail != NULL
    if (self.currentUser.email == NULL) {
        
        // this is a facebook user
        [self retrieveUserInfoFromFB];
    }
    
    // update locations for standard user
    // removed && self.crrentFBUserEmail == NULL
    if (self.currentUser.email != NULL) {
        
        // this is a standard login user (not facebook)
        [self retrieveLocations:self.currentUser.email];
    }
    
}


// handler for LoginViewControllerDelegate
- (void)loginViewHandler:(LoginViewController *)lvc handleObject:(id)object {
    
    NSLog(@"MainVC: [delegate] loginViewHandler:");
    
    NSArray *userArray = object;
    if (![userArray isKindOfClass:[NSArray class]]) {
        NSLog(@"... exception catch: not an array!");
        return;
    }
    
    if (userArray.count == 3) {
        self.currentUserEmail = [userArray objectAtIndex:0];
        self.currentUserName = [userArray objectAtIndex:1];
        self.currentUserURL = [userArray objectAtIndex:2];
        
        // show the current logged in user
        NSMutableString *nameText = [[NSMutableString alloc] initWithCapacity:60];
        [nameText appendString:NSLocalizedStringWithDefaultValue(@"NAME_LABEL", nil, [NSBundle mainBundle], @"Logged in: ", nil)];
        [nameText appendString:self.currentUserName];
        self.nameLabel.text = nameText;
        
    }
    else if (userArray.count == 2) {
        self.currentUserEmail = [userArray objectAtIndex:0];
        self.currentUserName  = [userArray objectAtIndex:1];
        
        // show the current logged in user name
        NSMutableString *nameText = [[NSMutableString alloc] initWithCapacity:60];
        [nameText appendString:NSLocalizedStringWithDefaultValue(@"NAME_LABEL", nil, [NSBundle mainBundle], @"Logged in: ", nil)];
        [nameText appendString:self.currentUserName];
        self.nameLabel.text = nameText;
        
    }
    else if (userArray.count == 1) {
        self.currentUserEmail = [userArray objectAtIndex:0];
        
        // No name, so show the current logged in user's email
        NSMutableString *nameText = [[NSMutableString alloc] initWithCapacity:60];
        [nameText appendString:NSLocalizedStringWithDefaultValue(@"NAME_LABEL", nil, [NSBundle mainBundle], @"Logged in: ", nil)];
        [nameText appendString:self.currentUserEmail];
        self.nameLabel.text = nameText;
    }
    else {
        NSLog(@"... exception catch: no objects!");
        return;
    }
    
    [self retrieveLocations:self.currentUserEmail];
    
}


// hander for LocationsViewControllerDelegate
- (void)locationViewRowDelete:(LocationsViewController *)lvc deleteItem:(NSInteger)item {
    
    [self.locationsArray removeObjectAtIndex:item];

    // update the badge and label
    [self updateBadgeAndLabel:[self.locationsArray count]];
    
}

// delegate handler for email sent by SignupVC to LoginVC intermediary.
// Running this is important on new user sign up.  We need to look for any shared locations and present them.
- (void)sendItemToMainVC:(LoginViewController *)lvc signupItem:(NSString *)email withName:(NSString *)name {
    
    NSLog(@" ===> sendItemToMainVC");
    
    self.currentUserEmail = email;             // what?  Is this the recipient email or user?
    self.currentUserName = name;
    
    // update the name label on view
    NSMutableString *nameText = [[NSMutableString alloc] initWithCapacity:60];
    [nameText appendString:NSLocalizedStringWithDefaultValue(@"NAME_LABEL", nil, [NSBundle mainBundle], @"Logged in: ", nil)];
    [nameText appendString:name];
    self.nameLabel.text = nameText;
    
    [self retrieveLocations:email];
    
}

#pragma mark - Address book delegates

// implement the required methods for the ABPeopleNavigationControler
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    
    NSLog(@"MainVC: peoplePicker shouldContinueAfterSelectingPerson:person property identifier");
    
    // remove the address book view
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
    
    // Return value
    // YES to display the contact and dismiss the picker.
    // NO to do nothing.
    return NO;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *) peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    
    NSLog(@"MainVC: peoplePickerNavController:peoplePicker shouldContinueAfterSelectingPerson");
    
    // Extract Address Book email address using a Bridge Transfer
    ABMultiValueRef emailAddresses = ABRecordCopyValue(person, kABPersonEmailProperty);
    if (ABMultiValueGetCount(emailAddresses) > 0) {
        self.recipientEmail = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(emailAddresses, 0);
        self.recipientName = (__bridge_transfer NSString *)ABRecordCopyCompositeName(person);
        self.recipientMugshot = (__bridge NSData *)ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail);              // added 3-10-14
    }
    else {
        self.recipientEmail = @"[None]";
        self.recipientName = @"[None]";
        self.recipientMugshot = nil;
    }
    
    
    // Get mobile number and choose iPhone number over other mobiles
    // http://stackoverflow.com/questions/1117575/how-do-you-get-a-persons-phone-number-from-the-address-book
    ABMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
    NSString* mobileLabel;
    for(CFIndex i = 0; i < ABMultiValueGetCount(phones); i++) {
        mobileLabel = (__bridge_transfer NSString *)ABMultiValueCopyLabelAtIndex(phones, i);
        if([mobileLabel isEqualToString:(NSString *)kABPersonPhoneMobileLabel])
        {
            self.recipientPhone = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phones, i);
        }
        else if ([mobileLabel isEqualToString:(NSString*)kABPersonPhoneIPhoneLabel])
        {
            self.recipientPhone = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phones, i);
            break ;
        }
    }
    
    NSLog(@"MainVC: peoplePickerNavController: Phone Number is: %@", self.recipientPhone);

    // remove the view controller
    [self dismissViewControllerAnimated:YES completion:^{
        
        // EMAIL ADDRESS CHECK.  Ensure recipient actually has an email before loading MapViewController
        if ([self.recipientEmail isEqualToString:@"[None]"]) {

            // no email address
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:NSLocalizedStringWithDefaultValue(@"ERROR_TITLE_NOEMAIL", nil, [NSBundle mainBundle], @"No email", nil)
                                      message:NSLocalizedStringWithDefaultValue(@"ERROR_MESSAGE_NOEMAIL", nil, [NSBundle mainBundle], @"The recipient selected does not have an email.  No problem, we'll send them a text message.", nil)
                                      delegate:nil
                                      cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"ERROR_DISMISS_OK", nil, [NSBundle mainBundle], @"OK", nil)
                                      otherButtonTitles:nil, nil];
            [alertView show];
            
            // added 7-2-14 changing the no email process
            [self performSegueWithIdentifier:@"showMap" sender:self];

            
        }
        else if (![self isStringValidEmail:self.recipientEmail]) {
            
            // Not a valid email, so tag it out 7-2-14
            self.recipientEmail = @"[Invalid]";
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:NSLocalizedStringWithDefaultValue(@"ERROR_TITLE_INVALID", nil, [NSBundle mainBundle], @"Invalid email", nil)
                                      message:NSLocalizedStringWithDefaultValue(@"ERROR_MESSAGE_INVALID", nil, [NSBundle mainBundle], @"Selected recipient does not have a valid email.  No problem, we'll send them a text message.", nil)
                                      delegate:nil
                                      cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"ERROR_DISMISS_OK", nil, [NSBundle mainBundle], @"OK", nil)
                                      otherButtonTitles:nil, nil];
            
            [alertView show];
            
            // added 7-2-14 changing the invalid email process
            [self performSegueWithIdentifier:@"showMap" sender:self];

        }
        else {
            // Catchall: valid email
            // There appears to be a valid email, go ahead and load the MapViewController via segue
            [self performSegueWithIdentifier:@"showMap" sender:self];
            
        }
    }];
    
    return NO;
}

#pragma mark - Navigation delegates

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
    
    NSLog(@"[delegate] MainViewController:peoplePickerNavigationControllerDidCancel");
    
    [self dismissViewControllerAnimated:YES completion:^{
        // completion code
    }];
}

// In prep for segue set the destination view's property for email
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"showMap"]) {
        
        NSLog(@"MainVC: prepareForSegue: showMap");
        
//        NSLog(@"... MainVC: c-rrentFBUserName = %@", self.currentFBUserName);
//        NSLog(@"... MainVC: c-rrentUser.username = %@", self.currentUser.username);
        NSLog(@"...> MainVC: c-rrentUserURL = %@", self.currentUserURL);
        
        // set emilAddr & rcipientName property in MpViewController
        MapViewController *mvc = [segue destinationViewController];
        [mvc setRecipientEmail:self.recipientEmail];
        [mvc setRecipientName:self.recipientName];
        
        // set the recipient's mobile number for use in SMS if needed to send invitation
        if (self.recipientPhone.length > 0) {
            [mvc setRecipientPhone:self.recipientPhone];
        }
        
        // set the recipient's image if avail 3-10-14
        if (self.recipientMugshot) {
            [mvc setRecipientImage:self.recipientMugshot];
        }
        
        // set the sender's username from Facebook profile
        if (self.currentUserName) {
            [mvc setSenderName:self.currentUserName];
        } else if (self.currentUser.username) {
            [mvc setSenderName:self.currentUser.username];
        } else {
            [mvc setSenderName:@""];
            NSLog(@"---> prepareForSegue: senderName ERROR (nil)");
        }
        
        // set the sender's URL property
        if (self.currentUserURL) {
            [mvc setSenderURL:self.currentUserURL];
        }
        
    }
    else if ([segue.identifier isEqualToString:@"showLocations"]) {
        
        // set locations array property in LocationsViewController
        LocationsViewController *lvc = [segue destinationViewController];
        [lvc setLocations:self.locationsArray];
        lvc.delegate = self;
        
    }
    else if ([segue.identifier isEqualToString:@"showLogin"]) {

        // instantiate the LoginViewController delegate here
        LoginViewController *loginViewController = [segue destinationViewController];
        loginViewController.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"showSettings"]) {
        
        // set the Facebook URL property to allow settings to show when FB access is authorized
        SettingsViewController *svc = [segue destinationViewController];
        [svc setCurrentUserURL:self.currentUserURL];
    }
    
}

#pragma mark - Button implementations

- (IBAction)logoutButton:(id)sender {
    
    // Call the logOut method on PFUser
    [PFUser logOut];
    
    // clear the current user info
    self.currentUserEmail = nil;
    self.currentUserName  = nil;
    self.currentUserURL   = nil;
    
//    self.crrentFBUserName  = nil;
//    self.crrentFBUserEmail = nil;
//    self.crrentFBUserURL   = nil;
    
    // also need to clear the locations array.  Changed from NULL 3-8-14
    self.locationsArray     = nil;
    
    // clear any recipient info
    self.recipientEmail     = nil;
    self.recipientName      = nil;
    self.recipientMugshot   = nil;
    
    // unload iAd
    [self removeADBannerView];
    
    // Clear the b-adge. Better than setting to zero with: [b-adge autoB-adgeSizeWithString:@"0"];
    [self.view sendSubviewToBack:self.badge];
    
    // locations counter
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.locationsCount = 0;
    
    [self performSegueWithIdentifier:@"showLogin" sender:self];
    
}


- (void)shareLocation:(id)sender {
    
    // unload iAd
    [self removeADBannerView];
    
    // perform segue to show map
    [self performSegueWithIdentifier:@"showMap" sender:self];
    
}

- (void)findFriends:(id)sender {
    
    // check if there are any locations before performing action
    if ([self.locationsArray count] > 0) {
    
        // stop iAd
        [self removeADBannerView];
    
        // show the locationsVC
        [self performSegueWithIdentifier:@"showLocations" sender:self];
    }
}

- (void)loadAddressBook:(id)sender {
    
    // unload iAd
    [self removeADBannerView];
    
    // load address book
    // Workaround for iOS 7.0.3, 7.0.4 on IPHONE 4, 4S when attempting to load MapView after invoking address book.
    NSString *ver = [[UIDevice currentDevice] systemVersion];
    float ver_float = [ver floatValue];
    
    if (ver_float < 7.1) {
        
        NSLog(@" ===> NOTICE: OLDER VERSION");
        // Using Class method instead on versions 7.0.3, 7.0.4.
        ABPeoplePickerNavigationController *picker = [[self class] sharedPeoplePicker];
        //    picker.peoplePickerDelegate = self;           // kif-kif
        [picker setPeoplePickerDelegate:self];
        [self presentViewController:picker animated:YES completion:nil];
        
    } else {
        
        // ios 7.1 or greater
        NSLog(@" ===> NOTICE: VERSION 7.1 or GREATER");
        
        // Original code used to invoke address book picker.  Use this when iOS 7.0.3 bug on iPhone 4/4S is fixed.
        ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
        [picker setPeoplePickerDelegate:self];
        [self presentViewController:picker animated:YES completion:nil];
    }
    
    // TODO: create array of friends to share location with
    
    // TODO: reload adds and pop back to main view
    
}

- (void)loadSettings:(id)sender {
    
    NSLog(@"MainVC: showSettings");
    
    // segue to the app settings screen
    [self performSegueWithIdentifier:@"showSettings" sender:self];
    
}


#pragma mark - ADBanner delegates

- (void)bannerViewDidLoadAd:(ADBannerView *)banner {
    [SharedAdBannerView setHidden:NO];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
    [SharedAdBannerView setHidden:YES];
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner {
    NSLog(@"MainVC: bannerViewActionDidFinish");
}

//This method adds shared adbannerview to the current view and sets its location to bottom of screen
//Should work on all devices

-(void) addADBannerViewToBottom
{

    SharedAdBannerView.delegate = self;
    //Position banner just below the screen
    SharedAdBannerView.frame = CGRectMake(0, self.view.bounds.size.height, 0, 0);
    //Height will be automatically set, raise the view by its own height
    SharedAdBannerView.frame = CGRectOffset(SharedAdBannerView.frame, 0, -SharedAdBannerView.frame.size.height);
    [self.view addSubview:SharedAdBannerView];
}

-(void) removeADBannerView
{

    SharedAdBannerView.delegate = nil;
    [SharedAdBannerView removeFromSuperview];
}


#pragma mark - Helper methods

// create a custom button with an bordered image for normal state, and no border for button pressed.  Text is defined using setTitle.
- (void)defineShareButton
{
    
    self.shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.shareButton addTarget:self action:@selector(shareLocation:) forControlEvents:UIControlEventTouchUpInside];
    [self.shareButton setBackgroundImage:[UIImage imageNamed:@"mainbuttonb-ns.png"] forState:UIControlStateNormal];
    [self.shareButton setBackgroundImage:[UIImage imageNamed:@"mainbuttonb.png"] forState:UIControlStateHighlighted];
    
    [self.shareButton setTitleColor:[UIColor colorWithRed:0.25f green:0.45f blue:0.90f alpha:1] forState:UIControlStateNormal];
    [self.shareButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    
    self.shareButton.alpha = 0.85;
    self.shareButton.titleLabel.font = [UIFont boldSystemFontOfSize:22.0f];
    self.shareButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.shareButton setTitle:NSLocalizedStringWithDefaultValue(@"MAP_BUTTON", nil, [NSBundle mainBundle], @"Map", nil) forState:UIControlStateNormal];

    CGFloat x, y, w, h;
    w = 242.0;
    h = 46.0;
    x = self.view.frame.size.width - w;           // was div 2.0f
    y = self.view.frame.size.height / 2.93f;      // was fixed at 130.0.  Was using Fibonacci 23.6% (4.237), now 2.63

    self.shareButton.frame = CGRectMake(x, y, w, h);
    
}

// create a custom button with an bordered image for normal state, and no border for button pressed.  Text is defined using setTitle.
- (void)defineFriendsButton
{
    
    self.friendsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.friendsButton addTarget:self action:@selector(findFriends:) forControlEvents:UIControlEventTouchUpInside];
    [self.friendsButton setBackgroundImage:[UIImage imageNamed:@"mainbuttonb-ns.png"] forState:UIControlStateNormal];
    [self.friendsButton setBackgroundImage:[UIImage imageNamed:@"mainbuttonb.png"] forState:UIControlStateHighlighted];
    
    [self.friendsButton setTitleColor:[UIColor colorWithRed:0.25f green:0.25f blue:0.50f alpha:1.0] forState:UIControlStateNormal];
    [self.friendsButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    
    self.friendsButton.alpha = 0.25;
    self.friendsButton.titleLabel.font = [UIFont boldSystemFontOfSize:22.0f];
    self.friendsButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.friendsButton setTitle:NSLocalizedStringWithDefaultValue(@"FRIENDS_BUTTON", nil, [NSBundle mainBundle], @"View Places", nil) forState:UIControlStateNormal];
    
    CGFloat x, y, w, h;
    w = 242.0;
    h = 46.0;
    x = self.view.frame.size.width - w;                     // was (self.view.frame.size.width - w) / 2.0f;
    y = (self.view.frame.size.height / 2.93f) + 92.0f;      // was 2.93f + 116.0f.
    
    self.friendsButton.frame = CGRectMake(x, y, w, h);
    
}

// create a custom button to pull up the address book.  This button will be below the Share Location Button.  Text is defined using setTitle.
- (void)defineAddressBookButton
{
    
    self.addressBookButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.addressBookButton addTarget:self action:@selector(loadAddressBook:) forControlEvents:UIControlEventTouchUpInside];
    [self.addressBookButton setBackgroundImage:[UIImage imageNamed:@"mainbuttonb-ns.png"] forState:UIControlStateNormal];
    [self.addressBookButton setBackgroundImage:[UIImage imageNamed:@"mainbuttonb.png"] forState:UIControlStateHighlighted];
    
    [self.addressBookButton setTitleColor:[UIColor colorWithRed:0.25f green:0.45f blue:0.90f alpha:1] forState:UIControlStateNormal];
    [self.addressBookButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    
    self.addressBookButton.alpha = 0.85;
    self.addressBookButton.titleLabel.font = [UIFont boldSystemFontOfSize:22.0f];
    self.addressBookButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.addressBookButton setTitle:NSLocalizedStringWithDefaultValue(@"ADDRESS_BUTTON", nil, [NSBundle mainBundle], @"Address Book", nil) forState:UIControlStateNormal];
    
    CGFloat x, y, w, h;
    w = 242.0;
    h = 46.0;
    x = self.view.frame.size.width - w;
    y = self.view.frame.size.height / 2.93f + 46.0f;        // was 2.93f + 58.0f
    
    self.addressBookButton.frame = CGRectMake(x, y, w, h);
    
}

- (void)defineSettingsButton
{
    
    self.settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.settingsButton addTarget:self action:@selector(loadSettings:) forControlEvents:UIControlEventTouchUpInside];
    [self.settingsButton setBackgroundImage:[UIImage imageNamed:@"mainbuttonb-ns.png"] forState:UIControlStateNormal];
    [self.settingsButton setBackgroundImage:[UIImage imageNamed:@"mainbuttonb.png"] forState:UIControlStateHighlighted];
    
    [self.settingsButton setTitleColor:[UIColor colorWithRed:0.25f green:0.45f blue:0.90f alpha:1] forState:UIControlStateNormal];
    [self.settingsButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    
    self.settingsButton.alpha = 0.85;
    self.settingsButton.titleLabel.font = [UIFont boldSystemFontOfSize:22.0f];
    self.settingsButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.settingsButton setTitle:NSLocalizedStringWithDefaultValue(@"SETTINGS_BUTTON", nil, [NSBundle mainBundle], @"Settings", nil) forState:UIControlStateNormal];
    
    CGFloat x, y, w, h;
    w = 242.0f / 2.0f;
    h = 46.0;
    x = self.view.frame.size.width - w;
    y = self.view.frame.size.height - 118.0f;         // place near bottom, just above iAd
    
    self.settingsButton.frame = CGRectMake(x, y, w, h);
    
}


- (void)showBadge:(NSString*)badgeString {
    
    // show the CustomB-adge on the lower button
    self.badge = [JSCustomBadge customBadgeWithString:badgeString];
    
    // Get the location of the 'Find My Friends' UIButton
    CGFloat x = (self.view.frame.size.width) - 25.0f;                   // was / 2.0f + 110.0f;
    CGFloat y = (self.view.frame.size.height / 2.93f) + 92.0f;          // was + 106.0f
    
    CGSize badgeSize = self.badge.frame.size;
    self.badge.frame = CGRectMake(x, y, badgeSize.width, badgeSize.height);
    
    // show the b-adge on top of the lower button as a subview
    [self.view addSubview:self.badge];
    
}

// Make the Parse.com call to find if there are any shared locations.
- (void)retrieveLocations:(NSString *)usingEmail;
{
    // get the locations object from Parse.com & set 'locations' property of LocationsViewController
    // moved this code from LocationsViewController
    NSLog(@"MainVC: retreiveLocations");
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // Changed from if (c-rrentUser.email == NULL)
    if (usingEmail == NULL) {
        NSLog(@"... MainVC: Exception caught - usingEmail is NULL");
        
        self.locationsArray = nil;
        appDelegate.locationsCount = 0;
        return;
    }
    
    PFQuery *query = [PFQuery queryWithClassName:@"UserLocation"];
    [query whereKey:@"emailAddress" equalTo:usingEmail];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        // stop activity indicator on competion
        [_activityIndicator stopAnimating];
        
        if (error) {
            
            // bummer, no internet connection or some other error | NSLog(@"Error: %@ %@", [error.userInfo objectForKey:@"error"], [error userInfo]);
            NSLog(@"... MainVC: PFQuery error");

            [self showFormattedError:error];
            [self logoutButton:nil];
            
        }
        else {
            // got shared locations.  Set the property that will be passed to LocationsViewController in segue
            self.locationsArray = (NSMutableArray*)objects;
            appDelegate.locationsCount = objects.count;
            
            // set the badge and label
            [self updateBadgeAndLabel:[objects count]];
            
        }
        // end of if (error-else) block
    }];
    // end of asynchronous query block findObjectsInBackgroundWithBlock
    
    [_activityIndicator startAnimating];

}

// facebook info handler
- (void)retrieveUserInfoFromFB {
        
    // Send request to Facebook
    FBRequest *request = [FBRequest requestForMe];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        
        // stop animation upon block completion
        [_activityIndicator stopAnimating];
        
        // handle response
        if (!error) {
            // Parse the data received
            NSDictionary *userData = (NSDictionary *)result;
            NSString *facebookID = userData[@"id"];
            
            NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
        
            // set the sender's user name
            if (userData[@"name"]) {
                
                self.currentUserName = userData[@"name"];
                
                // show the current logged in user
                NSMutableString *nameText = [[NSMutableString alloc] initWithCapacity:60];
                [nameText appendString:NSLocalizedStringWithDefaultValue(@"NAME_LABEL", nil, [NSBundle mainBundle], @"Logged in: ", nil)];
                [nameText appendString:self.currentUserName];
                self.nameLabel.text = nameText;
                
            }
            
            // set the sender email
            if (userData[@"email"]) {
                
                self.currentUserEmail = userData[@"email"];
                
                if (self.currentUserEmail.length > 0) {
                    // there appears to be FB email address, go ahead and update locations now.
                    [self retrieveLocations:self.currentUserEmail];
                }
            }
            
            // set the sender's facebook picture URL
            if ([pictureURL absoluteString]) {
                
                self.currentUserURL = [[pictureURL absoluteString] copy];
            }
            
        } else if ([[[[error userInfo] objectForKey:@"error"] objectForKey:@"type"]
                    isEqualToString: @"OAuthException"]) { // Since the request failed, we can check if it was due to an invalid session
            NSLog(@"MainVC: The facebook session was invalidated.  Invoking logout handler");
            
            // TODO: Be more selective of condition before forcing user out
            [self logoutButton:nil];
            
        } else {
            NSLog(@"MainVC: retreiveUserInfoFromFB: Some other error (doing nothing): %@", error);

            // Note: I was unable to easily extract the error message when in airplane mode
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedStringWithDefaultValue(@"ERROR_TITLE_CONNECT", nil, [NSBundle mainBundle], @"Connection Error", nil)
                                  message:NSLocalizedStringWithDefaultValue(@"ERROR_MESSAGE_CONNECT", nil, [NSBundle mainBundle], @"Unable to connect to Internet.", nil)
                                  delegate:nil
                                  cancelButtonTitle:nil
                                  otherButtonTitles:NSLocalizedStringWithDefaultValue(@"ERROR_DISMISS", nil, [NSBundle mainBundle], @"Dismiss", nil), nil];
            [alert show];
            
            // TODO: Create handler to allow user to retry connection after failure occurs
            [self logoutButton:nil];
            
        }
    }];
    
    // start animating activity indicator
    [_activityIndicator startAnimating];
    
}

- (void)updateBadgeAndLabel:(NSInteger)itemCount {
    
    // b4dge count
    NSString *badgeStr = [NSString stringWithFormat:@"%lu", (unsigned long)itemCount];
    
    // code to display, or hide the b4dge and frendsButton
    if (itemCount != 0)   {
        
//        NSLog(@" ... MainVC: rtrieveLocations:friends View In Subview: %@", [self.view.subviews containsObject:self.friendsButton] ? @"TRUE" : @"FALSE");
        // Check if the button is already displayed before adding another instance.
        if (![self.view.subviews containsObject:self.friendsButton]) {
            // subview does NOT contain the friendsButton object, so let's add and unhide in case it was previously hidden.
//            [self.view addSubview:self.friendsButton];
//            [self.friendsButton setHidden:NO];
            // set alpha & title colour
            [self.friendsButton setTitleColor:[UIColor colorWithRed:0.25f green:0.45f blue:0.90f alpha:1] forState:UIControlStateNormal];
            self.friendsButton.alpha = 0.85;
            
        }
        else {
            // button already exists, just need to unhide it
//            [self.friendsButton setHidden:NO];
            [self.friendsButton setTitleColor:[UIColor colorWithRed:0.25f green:0.45f blue:0.90f alpha:1] forState:UIControlStateNormal];
            self.friendsButton.alpha = 0.85;
        }
        
        // check to see if b4adge exists first before adding an instance. 2-23-14
        if (!self.badge) {
            // b-adge does not exist, let's add it.
            [self showBadge:badgeStr];
        }
        else {
            // b-adge already exists, so let's update it instead.
            [self.badge autoBadgeSizeWithString:badgeStr];
            
            // check if the badge was previously hidden 3-18-14
            if ([[self.view subviews] indexOfObject:self.badge] == 0) {
                
                [self.view bringSubviewToFront:self.badge];
            }
            
        }
    } else {
        // there are no locations being shared, so let's hide the button and b-adge after checking to make sure was created previously.
        NSLog(@"... MainVC: locationsCount = 0");
        
        if (self.badge) {
            [self.view sendSubviewToBack:self.badge];
//            [self.friendsButton setHidden:YES];
            // set title color and button alpha
            [self.friendsButton setTitleColor:[UIColor colorWithRed:0.25f green:0.25f blue:0.50f alpha:0.25] forState:UIControlStateNormal];
            self.friendsButton.alpha = 0.25;
        }
    }
}

// email check if an NSString is a vaild email.  Can be set for strict or lax filtering.  Also check for compliant email length.
-(BOOL) isStringValidEmail:(NSString *)checkString
{
    // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/

    if (checkString.length < 254) {
    
        BOOL stricterFilter = YES;
        NSString *stricterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
        NSString *laxString = @".+@([A-Za-z0-9]+\\.)+[A-Za-z]{2}[A-Za-z]*";
        NSString *emailRegex = stricterFilter ? stricterString : laxString;
        NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
        
        return [emailTest evaluateWithObject:checkString];
        
    } else {
        
        return FALSE;
    }
}

// return a range of text near a specific word http://stackoverflow.com/questions/18769777/how-to-get-a-range-to-text-near-a-specific-word-in-a-nsstring
// use:  NSString *snipVerb = [self getSnippetContaining:@"get" inString:userText numberOfWords:1];
- (NSString *)getSnippetContaining:(NSString *)keyword
                          inString:(NSString *)theString
                       separatedBy:(NSString *)theSeparator
                     numberOfWords:(NSUInteger)wordCount
{
    int keywordLength = (int)keyword.length;
    
    // check that rangeOfString:(keyword) and theString are not nil
    if (theString != nil && keyword != nil) {
        NSRange range = [theString rangeOfString:keyword
                                         options:NSBackwardsSearch
                                           range:NSMakeRange(0, theString.length)];
        if (range.location == NSNotFound) {
            return nil;
        }
        
        // pull the next word.  Do some error checking on this (location+keyworkLength bounds)
        if ((theString.length-1) > (range.location+keywordLength)) {
            
            NSString *substring = [theString substringFromIndex:range.location+keywordLength];
            NSArray *words = [substring componentsSeparatedByString:theSeparator];
            if (wordCount > words.count) {
                wordCount = words.count;
            }
            NSArray *snippetWords = [words subarrayWithRange:NSMakeRange(0, wordCount)];
            NSString *snippet = [snippetWords componentsJoinedByString:@" "];
            
            return snippet;
            
        } else {
            return nil;
        }
        
    } else {
        return nil;
    }
}

- (void)showFormattedError:(NSError *)error {
    
    // create a legible error message
    NSString *errorMessage = [error.userInfo objectForKey:@"error"];
    NSString *snipText = [self getSnippetContaining:@"NSLocalizedDescription=" inString:errorMessage separatedBy:@"," numberOfWords:1];
    
    // Check for returned NSLocalizedDescription text
    if (snipText.length == 0) {
        
        // There was no NSLocalizedDescription message so let's display the default message
        if (errorMessage.length > 90) {
            
            // Alert user of the error with this trimmed message when there's no NSLocalizedDescription
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:NSLocalizedStringWithDefaultValue(@"ERROR_TITLE", nil, [NSBundle mainBundle], @"Oops!", nil)
                                      message:[errorMessage substringToIndex:90]
                                      delegate:nil
                                      cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"ERROR_DISMISS", nil, [NSBundle mainBundle], @"Dismiss", nil)
                                      otherButtonTitles:nil, nil];
            [alertView show];
            
        } else if ((errorMessage.length > 1) && (errorMessage.length < 91)) {
            // Alert user of the error with this untrimmed message when there's no NSLocalizedDescription
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:NSLocalizedStringWithDefaultValue(@"ERROR_TITLE", nil, [NSBundle mainBundle], @"Oops!", nil)
                                      message:errorMessage
                                      delegate:nil
                                      cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"ERROR_DISMISS", nil, [NSBundle mainBundle], @"Dismiss", nil)
                                      otherButtonTitles:nil, nil];
            [alertView show];
        } else {
            // show fallback message
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:NSLocalizedStringWithDefaultValue(@"ERROR_TITLE_CONNECT", nil, [NSBundle mainBundle], @"Connection error", nil)
                                      message:NSLocalizedStringWithDefaultValue(@"ERROR_MESSAGE_CONNECT", nil, [NSBundle mainBundle], @"Unable to connect to Internet.", nil)
                                      delegate:nil
                                      cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"ERROR_DISMISS", nil, [NSBundle mainBundle], @"Dismiss", nil)
                                      otherButtonTitles:nil, nil];
            [alertView show];
        }
        
    } else {
        // There is a snipText to display (NSLocalizedDescription) so let's display that
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedStringWithDefaultValue(@"ERROR_TITLE", nil, [NSBundle mainBundle], @"Oops!", nil)
                                  message:snipText
                                  delegate:nil
                                  cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"ERROR_DISMISS", nil, [NSBundle mainBundle], @"Dismiss", nil)
                                  otherButtonTitles:nil, nil];
        [alertView show];
    }
}


@end

#pragma mark - Notes and TODOs

// TODOs:

// Version 1.1:

// - TESTING: When I deleted single location share, app popped back to MainVC with badge removed as expected.
// - FEATURE:  Localize the Settings VC
// - FUNCTIONALITY: See forced logout todos to be more selective before forcing logout
// - FEATURE: Consider allowing entry into app without logging in per WWDC2014 #230 "Skip for now"
// - FEATURE: (Marketing) Button to allow user to share app with friends on Facebook
// - LOOK & FEEL: MainVC "Logged in:" label not localized
// - LOOK & FEEL: Parse error messages are not localized in signup and login VC.
// - LOOK & FEEL: NSDate/Time not being shown properly in TableVC
// - BUG: Detail view (at bottom of view) is not setting the time and labels.
// - RELIABILITY: Need to check each helper method for NULL exception handlers and add if needed
// - SECURITY: Implement email verification to dissalow users from creating accounts with someone else's email address.  See Parse documentation.
// - RELIABILITY: Implement URL scheme fallback on persistent Parse.com error
// - LOOK & FEEL: If device capability does not include camera, do now show camera button in MapVC

// Version 1.2:

// - LOOK & FEEL: Change to tab-bar navigation
// - FEATURE: Dig deeper into PFAnalytics trckAppOpenedWithLaunchOptions
// - 106 & 221 talks from WWDC.  Sample code Dynamics Catalog.  Talk 226 bluring backgrounds.  Light effects etc.
// - FEATURE: Use UIDynamics WWDC talk.  Using UIAttachmentBehaviour = UICollisionBehavior.  Uses Pan Gesture Recognizer.  UIDynamicAnimator
// snap = [[UISnapBehavior alloc] initWithItem:littleBox snapToPoint:CGPointMake(160, 284)];
// AudioServicesPlaySystemSound(int)[self.valueForKey:variableName] integerValue]; instead of if else statements per Andrew on Stephen's code.
// - FEATURE: Allow sharing of location with multiple recipients at once
// - FEATURE: Allow addition of text with the location share map or snapshot
// - FEATURE: Show recipient FB profile image if available in MapVC.  Difficult to do due to lack of FB id in address book.
// - FEATURE: Show both map & facebook profile image side-by-side when available.  // - FEATURE: Can I get a "nearest place" based on GPS coordinates?
// - FEATURE: Let recipient know when user has moved from location.  Not necessarily expire location.
// - FEATURE: User should be able to share favorites, share with friend some options to meet.
// - FEATURE: Toddler Mom, student, other categories for finding locations to share with peers.
// - FEATURE: Meetup coordinated bulletin board
// - FEATURE: Timer filter based on venue open times
// - FEATURE: Ad-hoc meeting while driving, hands free mode with app suggesting venues.
// - FEATURE: Low energy blue-tooth proximity.
// - FEATURE: Help organize teams.  Special interest groups, classes etc.  Want to quickly be able to find out what are the.  Trade shows, arts and crafts.  Creating "interest filters".
// - FEATURE: Join the jam in progress.  Join to the tour etc.  Ad hoc events/meetings underway.
// - FEATURE: Scenario meeting at trailhead.  Being able to dynamically update location, refine.  Moving to new location.  Distance from old to new location.
// - FEATURE: Suggest interesting venues to user based on group's interests.
/* 
 It's also a good idea to de-register the view controller once you no longer need the notifications:
 
 - (void)viewWillDisappear:(BOOL)animated {
 [[NSNotificationCenter defaultCenter] removeObserver:self];
 }
*/
// Auto increment xCode build numbers: http://stackoverflow.com/questions/6286937/how-to-auto-increment-bundle-version-in-xcode-4/ and also http://stackoverflow.com/questions/6851660/version-vs-build-in-xcode-4

//********************************************************************************************************************
//
// DONE (VERSION 1.1):
//

// 07-15-14 - BUG: Push notifications don't seem to be working with app version submitted to App Store http://stackoverflow.com/questions/10987102/how-to-fix-no-valid-aps-environment-entitlement-string-found-for-application and http://stackoverflow.com/questions/1074546/the-executable-was-signed-with-invalid-entitlements
// 07-15-14 - LOOK & FEEL: Disable function when used selects disabled button (Locations shared button)
// 07-02-14 - LOOK & FEEL: Fix partially hidden "Login" button on Login screen
// 07-02-14 - FEATURE: If recipient does not have email, instead allow sender to enter manually and set app configuration to send data via SMS.
// 07-01-14 - LOOK & FEEL: Redo main button design to be flush on right edge
// 07-01-14 - LOOK & FEEL: Change to modern theme background images that Luke made
// 07-01-14 - LOOK & FEEL: Add inCaffeine logo to the App's startup image
// 06-30-14 - FEATURE: Settings screen needed to allow user to review app settings
// 06-24-14 - LOOK & FEEL: Show greyed out 'Find Friends' button on main screen.
// 06-24-14 - LOOK & FEEL: Redesign MainVC buttons to appear a bit more modern (using transparencies)
// 06-19-14 - HOUSEKEEPING: Upgraded laptop to Mavericks
// 06-18-14 - RELIABILITY: Added safety checks in MapVC for self.recipientEmail in methods that require it.
// 06-18-14 - LOOK & FEEL: Add explicit "Address Book" button to give user choice
// 06-17-14 - FEATURE: MapVC popup giving user option to sent invite via SMS or Email should first check device capability before giving option in popup.  http://stackoverflow.com/questions/2338546/several-uialertviews-for-a-delegate
// 06-17-14 - FEATURE: Adding direct app store link with: itms-apps://itunes.apple.com/us/app/snap-meet/id870848511?mt=8&uo=4 in MapVC -sendTextMessage & -sendEmailMessage
// 06-17-14 - FEATURE:  Update with app store link to facilitate download app to non-users.  http://stackoverflow.com/questions/433907/how-to-link-to-apps-on-the-app-store
// 05-07-14 - didUpdateToLocation was deprecated, replaced with didUpdateLocations and corresponding array of locations.

// (VERSION 1.0 - IN STORE):

// 04-07-14 - APP STORE ACCEPTANCE
// 04-29-14 - VALIDATION: Missing routing coverage file in iTunes Connect. Removed from listing as "Routing App"
// 04-29-14 - VALIDATION: Info.plist must not contain both UIMainStoryboard file and NSMainNibFile http://stackoverflow.com/questions/20886973/error-when-validating-ios-app
// 04-29-14 - VALIDATION: Nib file MainStoryBoard-ipad~ipad.nib not found
// 04-29-14 - VALIDATION:  Missing 120x120 http://stackoverflow.com/questions/18736954/missing-recommended-icon-file-the-bundle-does-not-contain-an-app-icon-for-iph
// 04-28-14 - SECURITY: Block application creation of columns and tables on Parse
// 04-28-14 - LOOK & FEEL: Application top of screen background color set per Ribbit sample.
// 04-28-14 - LOOK & FEEL: Sender name display changes in DetailVC.  MainVC logged in user name description & format.
// 04-26-14 - MARKETING: Screenshots taken for website
// 04-24-14 - MARKETING:  Create 1024x1024 icon image for App Store.
// 04-24-14 - LocationsVC table view format gets muddled on return to table view from DetailVC.  Fixed broken .h connection.  No idea how that affected placement.
// 04-23-14 - BUG: Mugshot is sent out Ok after initial Facebook login, but is not after app is restarted.  Fixed in MainVC viewDidLoad by adding an NSDictionary retrieval of picturURL from User/profile.
// 04-23-14 - BUG: Map image saved on Parse.com is blank.  Fixed with uncommented iOS 7.1 line in renderToImage in MapVC
// 04-23-14 - Restored app to email address and eliminate mobile number use for authentication
// 04-03-14 - LOOK & FEEL: Implement Auto-layout to support Internationalization.  WWDC 2013.  http://www.raywenderlich.com/20881/beginning-auto-layout-part-1-of-2 and http://www.raywenderlich.com/50319/beginning-auto-layout-tutorial-in-ios-7-part-2
// 04-03-14 - BUG: Signup with acceptable email, name and pwd is being denied during basic check routine.  Created if-else handler for different conditions.
// 04-02-14 - Completed translations for French, Vietnamese and Dutch.
// 04-02-14 - FEATURE: Internationalize app for version 1.1 (Spanish, French) http://www.appcoda.com/ios-programming-tutorial-localization-apps/ and http://www.raywenderlich.com/2876/localization-tutorial-for-ios
// 04-01-14 - FEATURE: Send text message to unregistered recipients.  http://www.exampledb.com/objective-c-iphone-send-sms.htm
// 03-31-14 - FEATURE: Send invitation email to unregistred recipients:  http://stackoverflow.com/questions/7087199/xcode-4-ios-send-an-email-using-smtp-from-inside-my-app
// 03-31-14 - FEATURE: Provide mechanism to send link to download app to non-users.  http://stackoverflow.com/questions/433907/how-to-link-to-apps-on-the-app-store
// 03-31-14 - BUG: LocationVC table does not show the default icon when missing Gravatar as fallback.
// 03-31-14 - FEATURE: Give user notification when a recipient does not have an account
// 03-31-14 - BUG: Need handler for gpsCoordinate being saved with 0.00000,0.00000 values when map didn't load.
// 03-30-14 - BUG: Prepare for segue from MainVC "senderName ERROR: (nil)"
// 03-30-14 - REFACTOR:  Create unified username/email etc no matter if an FB login or standard.  Refactored delegates and helper methods.
// 03-30-14 - Bug: Fixed failure error (Bad filename) when uploading missing map image.
// 03-29-14 - LOOK & FEEL: Add user name field in SignupVC, add name to Parse record, display on MainVC and send name on shared locations in MapVC.

// VERSION 0.9
// 03-28-14 - BETA TEST: Using TestFlight http://www.testflightapp.com/install/00c695cf3a685a94a32c46cae96e11da-MTAyOTg2MDg/
// 03-26-14 - RELIABILITY: Bounds checking in helper methods such as getSnippetContaining to avoid raising exceptions
// 03-25-14 - DEPLOYMENT:  Provisioned app for Ad-Hoc distribution and added to TestFlight.  Started inviting testers.
// 03/24/14 - MARKETING: Renaming app to Snap-Meet.  Getting error NSCocoaErrorDomain Code=3000 "no valid 'aps-environment' entitlement string found for application".  https://parse.com/tutorials/ios-push-notifications also https://developer.apple.com/account/ios/profile/profileList.action
// 03-23-14 - RELIABILITY:  Handle save/push failure notification when appDidEnterBackground on user exit?  Handled during appDidEnterForeground.
// 03-20-14 - SECURITY: Limit the number of shared locations to prevent spamming and one potential denial of service.  https://parse.com/questions/unique-fields--2
// 03-20-14 - SECURITY: Delete a shared location automatically after a 24 hour period.  http://stackoverflow.com/questions/22354329/how-to-delete-row-from-custom-class-after-a-day-of-createdat-by-using-cloudcode
// 03-19-14 - BUG: Minor, changed table view iconImage not showing map, loading default icon instead.
// 03-19-14 - USEABILITY:  Add communication error handlers.  Facilitate user retrying connection after failure occurs.
// 03-19-14 - BUG: Noted unexpected replacement of name after retreiveUserInfoFromFB call in standard login.  Fix loginViewHandler.
// 03-19-14 - FEATURE: Need to look for and show any previously shared locations on a new user's succesful signup
// 03-19-14 - FEATURE: Will need to pass email back to MainVC from SignupVC on new account creation
// 03-18-14 - FEATURE: Added UIActivity indicator on MainVC
// 03-18-14 - BUG: Previous user info not cleared after logout.  Also noted previous user info not cleared on new user signup in SignupVC
// 03-18-14 - BUG: Suzanne's Installation deviceToken is 'undefined'.  Was not set in SignupVC.
// 03-18-14 - BUG: After FB login the logged on user is not displayed on MainVC
// 03-17-14 - LOOK & FEEL:  Made login views conform to best practices.  https://developers.facebook.com/docs/facebook-login/checklist/
// 03-17-14 - BUG: Facebook login error:  "The developers ... have not set up this app ... for Facebook Login".  Set option in Facebook developer settings.
// 03-17-14 - LOOK & FEEL: Make privacy notice a link or separate page instead.
// 03-17-14 - BUG: Fixed 2X call to shreUserLocation in MapVC by placing in else statement
// 03-17-14 - BUG: Need to make lowercase each user email before saving.
// 03-17-14 - LOOK & FEEL: Simplify user interface in MapVC.  Change 'Share/Send' button to make it more obvious, and remove 'Update' button.
// 03-17-14 - BUG: Look into UserLocation senderName (Unspecified sender for Suzanne).  senderDevice is Ok.  Fixed by sending MapVC @"" instead from MainVC and testing for zero length in LocationsVC
// 03-14-14 - FEATURE: Add delete button to DetailVC
// 03-14-14 - BUG: Minor, need to figure way to clear the external badge.  Clearing to zero on entry.
// 03-14-14 - BUG: Location count not being set on app re-entry upon receipt of push notification.  Same issue within app.  App is decrementing locations count (appdelegate.locationsCount) after loading mapnav, but this is not being shown onscreen.
// 03-13-14 - BUG:  User taking video caused app to freeze.  Need to block and force photos only.  http://stackoverflow.com/questions/6943343/remove-photo-video-switch-in-standard-uiimagepickercontroller-in-order-to-force
// 03-13-14 - LOOK & FEEL: Snapshot displayed in DetailVC is landscape, but should be portrait. http://stackoverflow.com/questions/4881512/how-to-know-if-photo-in-landscape-or-portrait-mode Also look into UIViewContentModeScaleAspectFit
// 03-13-14 - LOOK & FEEL:  (Also app store req.) Create versions of each image used in app for various devices
// 03-13-14 - LOOK & FEEL: Add activity loading indicators (UIActivityIndicatorView) to SignupVC and standard login in LoginVC
// 03-12-14 - FEATURE: Allow user in LocationsVC to view both map and snapshot when selecting table row.
// 03-12-14 - LOOK & FEEL: redesign MainVC buttons so that text is not embedded in the button image
// 03-11-14 - LOOK & FEEL: In LocationsVC table view place a border around the images to make them look like buttons.
// 03-11-14 - BUG: Resolve issue of not uploading snapshot in MapVC.  Solved with completion block management.
// 03-11-14 - FEATURE: Allow user to take a snapshot and include that with the shared GPS location.
// 03-11-14 - LOOK & FEEL:  Placed side-by-side sender mugshot & map icon in LocVC tableviews
// 03-11-14 - FEATURE:  Show Gravatar image for receipient if FB image not available both in MapVC and LocVC tables.
// 03-10-14 - FEATURE: Show address book recipient image as thumbnail in MapVC. http://stackoverflow.com/questions/2085959/get-image-of-a-person-from-iphone-address-book
// 08-09-14 - LOOK & FEEL: Display map image for LocationView rows when user image URL not available
// 03-08-14 - BUG: On standard logout/login, the b4dge l0cationsCount does not get set properly.  L0cations array does however.
// 03-08-14 - CLEANUP: Removed @synthesize for s-hareButton, f-riendsButton, b-adge, c-rrentUser, l-cationsArray to ref. via self instead.
// 03-06-14 - BUG: I am no longer getting push notifications at all. didRegisterForRemoteNotificationsWithDeviceToken not being called.  Bundle rename issue w/ http://stackoverflow.com/questions/13432203/no-valid-aps-environment-entitlement-string-found-for-application
// 03-06-14 - FUNCTIONALITY:  Look into if it would be better to setInstallObject (PFInstallation) in SignupVC intead.  No because I need to set the install token to a new user if someone else logs in to use the app.
// 04-04-14 - BUG: Now getting sender's FB details async instead of: self.currentFBUserName = [self getSnippetContaining:@"firstandlast = " inString:c-rrentUser.description separatedBy:@";" numberOfWords:1];
// 03-04-14 - BUG: I'm losing the currentFBUserURL image path on app close and re-open without login.  This is likely because the MainViewController instances are destroyed on app restart.
// 03-03-14 - FEATURE: Pass the sender's photo (senderPhoto URL) to MapVC and save it in a new column in UserLocation class
// 03-03-14 - BUG: LocationsView cell shows the Facebook identifier# instead of the name.  Fixed in ViewDidLoad
// 03-03-14 - FEATURE: Save the sender's name in a new column (senderName) in UserLocation class at Parse.com
// 03-03-14 - BUG: On completion of Facebook login, the MainViewCon l-cationsArray is not being populated.
// 03-03-14 - BUG: Delegate set currentFBUserEmail http://chrisrisner.com/31-Days-of-iOS--Day-6%E2%80%93The-Delegate-Pattern
// 03-02-14 - USEABILITY: Allow user to signup using another API such as Facebook, Instagram, Twitter, or LinkedIn
// 03-01-14 - USABILITY: Need to be able to dismiss the keyboard when user chooses to do so in LoginViewController & Signup
// 02-26-14 - BUG: Convert map to image is not working properly.  Fixed by using MKMapView delegate instead.
// 02-26-14 - REVENUE:  Implement advertisement display capability in-app.  http://stackoverflow.com/questions/16471240/using-iads-on-ipad-crashes-after-huge-number-of-calls-to-bannerviewdidfailtorec
// 02/24/14 - LOOK & FEEL: NSSortDescriptor for locations order reverse in L0cationViewController.  Used simple index math instead.
// 02/23/14 - BUG:  Need consistent updates of locations array no matter what state the app is in when receiving a push notification.  Redesigned method flow in w/ NSNotifications.
// 02/23/14 - BUG:  r-freshFriendsButton l-cationsArray.count needs to be decremented only when app is backgrounded on navigation/map load.  Redesigned method flow & NSNotifications.
// 02/22/14 - RELIABILITY: Remediate GravatarUrlBuilder value conversion issue with 'unsigned long' loses integer precision
// 02/20/14 - LOOK & FEEL: Bigger table rows for LocationView using custom LocationTableCell.xib
// 02/17/14 - LOOK & FEEL: Hide 'Find My Friends' button when there are not locations being shared for signed in user
// 02/17/14 - LOOK & FEEL: Create better looking navigation labels in the Main View.  http://www.guilmo.com/how-to-create-a-uibutton-programmatically/
// 02/15/14 - LOOK & FEEL: Handle network connection error messages by alerting user in a human readable format when able
// 02/15/14 - LOOK & FEEL: Change the error message in the Login and Signup views to a human readable format too
// 02/14/14 - FUNCTIONALITY: Add sender's name (Device name) to the fields being sent to the recipient via Parse
// 02/14/14 - FUNCTIONALITY: Show the sender's device name in the LocationsViewController rows
// 02/13/14 - RELIABILITY: Remediate JSCustomBounds deprecated methods with iOS 7 compliant ones.
// 02/13/14 - RELIABILITY: Check email when appending the NSMutable string message that is being sent as a push notifaction.  Check for overflow or other constraints.
// 02/13/14 - RELIABILITY: Do more bounds checking before saving the recipient's email address to Parse.  Don't allow corrupt email addresses.
// 02/13/14 - RELIABILITY:  Check email bounds < 254 that could cause an overflow.
// 02/12/14 - BUG: In LocationsViewController the row picked index is an issue.  Need to resolve.
// 02/11/14 - EFFICIENCY: Need to set locations object in LocationsViewController from MainViewController to maintain Parse efficiency.  I don't want to have to call this more than once
// 01-27-14 - BUG: Issue I'm having is on iPad and iPhone 4 after selecting recipient, addressBook gets dismissed, but Map View doesn't load, app closes instead.  See notes in MapViewController
// -[_UIBackdropColorSettings barStyle]: unrecognized selector sent to instance 0x176d1f80.  This behavior appeared with the iOS 7.0.3 update on iPhone 4, 4S.
// 01-27-14 - Convoluted workaround for the iPhone 4,4S crash https://discussions.apple.com/thread/5498630?start=15&tstart=0

