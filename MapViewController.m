//
//  Controller.m
//  Snap Meet
//
//  Created by chris on 1/14/14.
//  Copyright (c) 2014 Chris Jungmann. All rights reserved.
//

#import "MapViewController.h"
#import "GravatarUrlBuilder.h"

// Used to handle different UIAlertView button configurations in -checkRecipientAccount 6-17-14
#define kAlertViewBoth 1
#define kAlertViewSMS  2
#define kAlertViewMail 3
#define kAlertViewNone 4

@interface MapViewController ()
@end

@implementation MapViewController
@synthesize currentUser;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // test access to emailAddr posted from MainViewController
//    NSLog(@"MapVC: viewDidLoad with email %@", self.recipientEmail);
    
    // set the device name to identify the sender in a more friendly manner.  2-14-14
    self.deviceName = [[UIDevice currentDevice] name];
    
    // set the recipient's image thumbnail if it exists, otherwise show default icon
    if (self.recipientImage) {
        UIImage *thumbnail = [UIImage imageWithData:self.recipientImage];
        self.avatarView.image = thumbnail;
    } else {
        [self retrieveGravatar];            // an async call, icon is loaded first on the next line
        self.avatarView.image = [UIImage imageNamed:@"coffeelogo"];
    }
    
    // check if we have previously selected a recipient with email address
    if (self.recipientEmail) {
        
        // set text properties for the labels
        self.emailLabel.text = self.recipientEmail;
        self.recipientLabel.text = self.recipientName;
        
        // we should check if the recipient has an account here to notify the sender before going further.  Ensure you're not making a Parse network call unnecessarily
        if (![self.recipientEmail isEqualToString:@"[None]"] || ![self.recipientEmail isEqualToString:@"[Invalid]"]) {
            
            [self checkRecipientAccount:self.recipientEmail];
        }
        
    }
    
    // + (CLAuthorizationStatus)authorization  -   kCLAuthorizationStatusDenied
    
    // check if location services are enabled
//    if (![CLLocationManager locationServicesEnabled]) {
//        NSLog(@"MapVC: Location Services NOT enabled");
//        
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location Service Disabled"
//                                                        message:@"To re-enable, please go to Settings and turn on Location Service for Snap Meet."
//                                                       delegate:nil
//                                              cancelButtonTitle:@"OK"
//                                              otherButtonTitles:nil];
//        [alert show];
//
//    } else {
//        
//        NSLog(@"MapVC: Location Services enabled");
//        // Initial creation of locationManager object and startMonitoring
//        self.locationManager = [[CLLocationManager alloc] init];
//        // iOS 8 requires this
//        if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
//            [self.locationManager performSelector:@selector(requestWhenInUseAuthorization)];
//        self.locationManager.delegate = self;
//        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
//        self.locationManager.distanceFilter = kCLDistanceFilterNone;
//        [self.locationManager startMonitoringSignificantLocationChanges];
////        [self.locationManager startUpdatingLocation];
//    }
    
    // revised location service activation
    [self determineLocation:YES];
    
    // set button border and background color
    self.sendButtonOutlet.layer.borderColor = [[UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:0.5] CGColor];
    self.sendButtonOutlet.backgroundColor   = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:0.1];
    
  
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
}

#pragma mark - Location methods

// Deprecated
//- (void) getLocation {
//    
//    // recommended use of this method instead to get an initial location.  Uses fewer resources.
//    [self.locationManager startMonitoringSignificantLocationChanges];   //    [self.locationManager startUpdatingLocation];
//}

// activate or deactivate location service, added from Act 420 app
- (void)determineLocation:(BOOL)activated {
    // 'activated' drives the process on/off
    if (activated) {
        // check if user disabled the service
        if (([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) || ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted)) {
            NSLog(@"Location Service Denied or Restricted");
            return;
        }
        // check device capability before alloc/init which can cause exception if device not capable
        if (![CLLocationManager locationServicesEnabled]) {
            NSLog(@"Location Service Disabled");
            
        } else {
            // let's activate, but first check if it's already active
            if (self.locationManager) {
                // already allocated and initialized, just activate
                [self.locationManager startMonitoringSignificantLocationChanges];
                
            } else {
                
                // Initial creation of locationManager object and startMonitoring
                self.locationManager = [[CLLocationManager alloc] init];
                // iOS 8 requires this
                if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
                    [self.locationManager performSelector:@selector(requestWhenInUseAuthorization)];
                self.locationManager.delegate = self;
                self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
                self.locationManager.distanceFilter = kCLDistanceFilterNone;
                [self.locationManager startUpdatingLocation];
            }
        }
    } else {
        // shut her down
        if ([CLLocationManager locationServicesEnabled]) {
            
            if (self.locationManager) {
                [self.locationManager stopUpdatingLocation];
                self.locationManager = nil;
            }
        }
    }
}


#pragma mark - CLLocationManagerDelegates

// didUpdateToLocation is deprecated, replaced with didUpdateToLocations with an array
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
//    NSLog(@"MapVC: didUpdateLocations:");
    
    CLLocation *newLocation = [locations lastObject];
    self.currentLocation = newLocation;

    if(newLocation.horizontalAccuracy <= 100.0f){
        
        [self.locationManager stopUpdatingLocation];
//        NSLog(@"MapVC: Delegate: didUpdateLocationS - stopUpdatingLocation");
    }
    
    // Winning's GPS coordinates for testing
//    CLLocationCoordinate2D myCoordinate = CLLocationCoordinate2DMake(35.080786, -106.620968);
    CLLocationCoordinate2D myCoordinate = newLocation.coordinate;
    
    // newLocation.coordinate.longitude and latitude properties
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(myCoordinate, 250, 250);     // 500, 500
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion];
    [self.mapView setRegion:adjustedRegion animated:YES];
    self.mapView.showsUserLocation = YES;
    self.mapView.delegate = self;       // Resolving why MKMapView delegates are not invoked 2-26-14

}


// failed to get location.  Alert the user.
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    UIAlertView *errorAlert = [[UIAlertView alloc]
                               initWithTitle:NSLocalizedStringWithDefaultValue(@"ERROR_TITLE_GPS", nil, [NSBundle mainBundle], @"Location Service error", nil)
                               message:NSLocalizedStringWithDefaultValue(@"ERROR_MESSAGE_GPS", nil, [NSBundle mainBundle], @"Unable to get your location.", nil)
                               delegate:nil
                               cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"ERROR_DISMISS", nil, [NSBundle mainBundle], @"Dismiss", nil)
                               otherButtonTitles:nil];
    [errorAlert show];
}

#pragma mark - MKMapViewDelegates

// this delegate is called when the map is finished rendering completely
- (void)mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered {
    
//    NSLog(@"MapVC: Delegate: mapViewDidFinishRenderingMap:fullyRendered");
    
    // Call renderToImage and save image property
    self.mapImage = [self renderToImage:self.mapView];
    
    [self updateCurrentLabel];
    
}

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView {
    
//    NSLog(@"MapVC: Delegate: mapViewDidFinishLoadingMap");
    
}

- (void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error {
    
    NSLog(@"MapVC: Delegate: mapViewDidFailLoadingMap error: %@", error);
    
}

//-------------------------------------------------------------------------------------------------------------

#pragma mark - ADBanner delegates

- (void)bannerViewDidLoadAd:(ADBannerView *)banner {
    [SharedAdBannerView setHidden:NO];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
    [SharedAdBannerView setHidden:YES];
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner {
//    NSLog(@"MapVC: Delegate: bannerViewActionDidFinish");
}

//This method adds shared adbannerview to the current view and sets its location to bottom of screen
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

#pragma mark - Camera delegates

- (BOOL) startCameraControllerFromViewController: (UIViewController*) controller
                                   usingDelegate: (id <UIImagePickerControllerDelegate,
                                                   UINavigationControllerDelegate>) delegate {
    
    
    if (([UIImagePickerController isSourceTypeAvailable:
          UIImagePickerControllerSourceTypeCamera] == NO) || (delegate == nil) || (controller == nil))
        return NO;
    
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    // Displays a control that allows the user to choose picture or movie capture, if both are available:
//    cameraUI.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
    
    // Hides the controls for moving & scaling pictures, or for trimming movies. To instead show the controls, use YES.
    cameraUI.allowsEditing = NO;
    
    // Hide the video option
//    cameraUI.showsCameraControls = NO;
    cameraUI.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
    cameraUI.delegate = delegate;
    [self presentViewController:cameraUI animated:YES completion:nil];

    return YES;
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
//    NSLog(@"MaViewController: imagePickerController");
    // check if photo or video (Uses <MobileCoreServices/UTCoreTypes.h>)
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        
        // a photo was taken or selected
        self.snapshot = [info objectForKey:UIImagePickerControllerOriginalImage];
        
        // check that the camera is being used .. don't save an image already on the phone
        if (self.photoPicker.sourceType == UIImagePickerControllerSourceTypeCamera) {
            // save the image
            UIImageWriteToSavedPhotosAlbum(self.snapshot, nil, nil, nil);
            
        }
        
    }
    else {
        // a video was taken
        return;
        
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

#pragma mark - Message Composer delegates

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    if (error) NSLog(@"ERROR - mailComposeController: %@", [error localizedDescription]);
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    return;
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {

    [self dismissViewControllerAnimated:YES completion:nil];
    
    return;
}


#pragma mark - Alertview delegate

// Modified this to properly handle index when there is only one device in list of capabilities (using kAlertView tag)
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

//    NSLog(@"---> Button index %li", (long)buttonIndex);
//    NSLog(@"---> Number of buttons %li", (long)[alertView numberOfButtons]);

    if (alertView.tag == kAlertViewBoth) {
        
        if (buttonIndex == 1) {
            
            // Send invitation via text message
            NSArray *recipients = [NSArray arrayWithObjects:self.recipientPhone, nil];
            [self sendTextMessage:recipients];
            
        } else if (buttonIndex == 2) {
            
            // Send invitation via email
            NSArray *recipients = [NSArray arrayWithObjects:self.recipientEmail, nil];
            [self sendEmailMessage:recipients];
            
        }
        
    } else if (alertView.tag == kAlertViewSMS) {
        
        if (buttonIndex == 1) {
            
            // Send invitation via text message
            NSArray *recipients = [NSArray arrayWithObjects:self.recipientPhone, nil];
            [self sendTextMessage:recipients];
            
        }
        
    } else if (alertView.tag == kAlertViewMail) {
        
        if (buttonIndex == 1) {
        
            // Send invitation via email
            NSArray *recipients = [NSArray arrayWithObjects:self.recipientEmail, nil];
            [self sendEmailMessage:recipients];
        
        }
    
    } else if (alertView.tag == kAlertViewNone) {
        
        // no other option than bring up phone dailer?
        // TODO: Determine handler for that one in a million user that has no email or SMS capability
        
    }
    
}

#pragma mark - Implement the button controls

//- (IBAction)updateCurrentLocation:(id)sender {
//    
//    [self getLocation];
//}


- (IBAction)sendLocationButton:(id)sender {
    
//    NSLog(@"sendLocationButton: Current GPS location: %f", self.currentLocation.coordinate.latitude);
    
    // 06-24-14 check if the user is logged in and show login screen if not
    if (!self.senderName) {
        
        [self performSegueWithIdentifier:@"showLogin" sender:self];
    }
    
    // check if we have a GPS location before going any further
    if (self.currentLocation.coordinate.latitude == 0.0 && self.currentLocation.coordinate.longitude == 0.0) {
        
        // show error message missing GPS coordinates
        NSLog(@"=> Missing GPS location");
        UIAlertView *errorAlert = [[UIAlertView alloc]
                                   initWithTitle:NSLocalizedStringWithDefaultValue(@"ERROR_TITLE_GPS", nil, [NSBundle mainBundle], @"GPS error", nil)
                                   message:NSLocalizedStringWithDefaultValue(@"ERROR_MESSAGE_GPS", nil, [NSBundle mainBundle], @"Unable to get your location.", nil)
                                   delegate:nil
                                   cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"ERROR_DISMISS", nil, [NSBundle mainBundle], @"Dismiss", nil)
                                   otherButtonTitles:nil];
        [errorAlert show];

    } else {
        
        // We have non-zero GPS coordinates, go ahead and do everything
        // Ensure that the recipient actually has an email address, so we don't save "[None]" on Parse.com
        if ([self.recipientEmail isEqualToString:@"[None]"] || [self.recipientEmail isEqualToString:@"[Invalid]"]) {
        
            NSLog(@"MapVC: sendLocationButton: email check exception caught (None or Invalid)");
            // No email address - so alert user and don't save.
            
            [self noEmailHandler];
            
        } else if (!self.recipientEmail) {
            
            NSLog(@"MapVC: sendLocationButton: email check - user has not selected a recipient");
            [self noEmailHandler];

        } else {
    
            // Call helper method to save the map image, snapshot and user location to the Parse cloud
            [self uploadMessage];       // calls save-UserLocation, checkRecipientAccount & send-PushNotification on completion 3-19-14

        }
    
        // remove iAd
        [self removeADBannerView];

        // Stop updating location and return to the initial controller (MainViewController)
        [self.locationManager stopUpdatingLocation];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)cameraButton:(id)sender {
    
    // unload iAd
    [self removeADBannerView];

    // invoke the camera
    [self startCameraControllerFromViewController:self usingDelegate:self];

}


- (IBAction)cancelButton:(id)sender {
    
    [self.locationManager stopUpdatingLocation];
    
    // remove iAd
    [self removeADBannerView];
    
    // Pop to root view controller
    [self.navigationController popViewControllerAnimated:YES];

}

#pragma mark - Helper methods

- (void) updateCurrentLabel
{
//    NSString *latitude = [NSString stringWithFormat:@"%f", self.currentLocation.coordinate.latitude];
//    NSString *longitude = [NSString stringWithFormat:@"%f", self.currentLocation.coordinate.longitude];
//    self.latitudeLabel.text = [NSString stringWithFormat: @"GPS: %@,%@", latitude, longitude];
    
    // load iAd adverts now
    [self addADBannerViewToBottom];
    
}

// this method uploads map icon, and sender snapshot (if photo was taken) along with the GPS location
// The helper method sveUserLocation is used to associate the file uploads with the row and commit the final upload
- (void) uploadMessage {
    
    NSData   *mapFileData;
    NSString *mapFileName;
    NSString *mapFileType;
    
    // check if map image exists
    if (self.mapImage != nil) {
        
//        NSLog(@"---> uploadMap: image Ok.");
        
        // could also look at device specs
        UIImage *newImage = [self resizeImage:self.mapImage toWidth:320.0f andHeight:480.0f];
        mapFileData = UIImagePNGRepresentation(newImage);
        mapFileName = @"image.png";
        mapFileType = @"image";
        
    }
    else {

//        NSLog(@"---> uploadMap: no image.");

        // set values to nil
        mapFileData = nil;
        mapFileName = @"image.png";
        mapFileType = @"image";
        
    }
    
    NSData   *snapFileData;
    NSString *snapFileName;
    NSString *snapFileType;
    
    // check if user took a photo
    if (self.snapshot != nil) {
        
//        NSLog(@"---> uploadSnapshot: got an image to process");
        // could look at device specs, but let's not for now
        UIImage *newImage = [self resizeImage:self.snapshot toWidth:320.0f andHeight:480.0f];
        
        snapFileData = UIImageJPEGRepresentation(newImage, 0.33f);
        snapFileName = @"snap.jpg";
        snapFileType = @"image";            // jpeg
        
    } else {
        
//        NSLog(@"---> uploadSnapshot: no image.");
        // Add code to support videos in V2.0 (maybe)
        //        fileData = [NSData dataWithContentsOfFile:self.videoFilePath];
        //        fileName = @"video.mov";
        //        fileType = @"video";
        
        snapFileData = nil;
        snapFileName = @"snap.jpg";
        snapFileType = @"image";
        
    }
    
    // upload the map file
    PFFile *mapPFFile = [PFFile fileWithName:mapFileName data:mapFileData];
    [mapPFFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        // this block called upon completion of the map image upload
        if (error) {
            
            [self showFormattedError:error];
            
            // error handler
            NSInteger errCode = [error code];
            if (kPFErrorConnectionFailed == errCode || kPFErrorInternalServer == errCode) {
//                [mapPFFile saveEventually];
                NSLog(@"==> ERROR: kPFErrorConnectionFailed");
            }
            
            
        } else {
            
            // File is on parse.com.  2nd half of upload process is to associate file
            PFObject *userLocation = [PFObject objectWithClassName:@"UserLocation"];
            
            [userLocation setObject:mapPFFile forKey:@"mapFile"];
            [userLocation setObject:mapFileType forKey:@"fileType"];
            
            // check to see if there's also a snapshot to upload
            if (self.snapshot != nil) {
                
//                NSLog(@"---> ... Uploading snapshot!");
                
                PFFile *snapPFFile = [PFFile fileWithName:snapFileName data:snapFileData];
                [snapPFFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    
                    // this block called upon completion of the image upload
                    if (error) {
                        
                        [self showFormattedError:error];
                        
                    } else {
                        
                        [userLocation setObject:snapPFFile forKey:@"snapFile"];
                        [userLocation setObject:snapFileType forKey:@"snapType"];
                        
                        // now commit & associate the file upload while saving the user location
                        [self saveUserLocation:userLocation];
                    }
                
                }]; // end snapPFFile save in background
                
            } else {
                
                // now commit & associate the file upload while saving the user location (only is there's no snapshot to avoid calling twice)
                [self saveUserLocation:userLocation];
                
            } // end if (snapshot)
            
        } // end else-if (error)
        
    }]; // end mapPFFile save in background
}

// this method is called by up-loadMessage
- (void)saveUserLocation:(PFObject *)userLocation {
    
    // added 6-18-14
    if (!self.recipientEmail) {
        return;
    }
    
    // Using synthesized property instead of [PFUser *currentUser] 2-12-14
    currentUser = [PFUser currentUser];
    
    // recipient info
//    NSLog(@"MapVC: save-UserLocation: email: %@", self.recipientEmail);
    if (self.recipientEmail) {
        userLocation[@"emailAddress"] = self.recipientEmail;
    }
    
    // prepare to save the sender's email address.  Converted to force lowercase on 3-17-14
    if (currentUser.username) {
        userLocation[@"senderEmail"] = [currentUser.username lowercaseString];
    }
    
    // added the sender's device name 2-14-14
    if (self.deviceName) {
        userLocation[@"senderDevice"] = self.deviceName;
    }
    
    // added the sender's name now that Facebook login provides it 3-3-14
    if (self.senderName) {
        userLocation[@"senderName"] = self.senderName;
    }
    
    // added the sender's profile picture URL 3-3-14
    if (self.senderURL) {
        userLocation[@"senderURL"] = self.senderURL;
    }
    
    // save the location after reformatting the float to a string
    NSMutableString *gpsMutableLocation = [[NSMutableString alloc] initWithCapacity:50];
    
    NSString *latitude = [NSString stringWithFormat:@"%f", self.currentLocation.coordinate.latitude];
    NSString *longitude = [NSString stringWithFormat:@"%f", self.currentLocation.coordinate.longitude];
    
    [gpsMutableLocation appendString:latitude];
    [gpsMutableLocation appendString:@","];
    [gpsMutableLocation appendString:longitude];
    
    NSString *gpsLocation = [NSString stringWithString:gpsMutableLocation];
    userLocation[@"gpsCoordinate"] = gpsLocation;
    
    [userLocation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            
            [self showFormattedError:error];
            
        } else {
            
            // everything was successful!
            [self sendPushNotification];
            
            // Moved this to completion block instead as it could otherwise be invoked on failure
            NSMutableString *successMsg = [[NSMutableString alloc] initWithCapacity:50];
            [successMsg appendString:NSLocalizedStringWithDefaultValue(@"SUCCESS_MESSAGE", nil, [NSBundle mainBundle], @"Location shared with ", nil)];
            [successMsg appendString:self.recipientEmail];
            
//            NSLog(@"sendLocationButton:Success: %@", successMsg);
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:NSLocalizedStringWithDefaultValue(@"SUCCESS_TITLE", nil, [NSBundle mainBundle], @"Success!", nil)
                                      message:successMsg
                                      delegate:nil
                                      cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"ERROR_DISMISS_OK", nil, [NSBundle mainBundle], @"OK", nil)
                                      otherButtonTitles:nil, nil];
            
            [alertView show];
        }
    }];
}

- (void)checkRecipientAccount:(NSString *)recipientEmail {
    
    if (!recipientEmail) {
        return;
    }
    
    PFQuery *query = [PFUser query];
    [query whereKey:@"email" equalTo:recipientEmail];
    
//    PFQuery *query = [PFQuery queryWithClassName:@"User"];
//    [query whereKey:@"email" equalTo:recipientEmail];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (error) {
            
            // error completing query
            NSLog(@"=> unable to checkRecipientAccount");
            
            [self showFormattedError:error];
            
        } else {
            
            // recipient exists
//            NSLog(@"MapVC: checkRecipientAccount: objects count: %lu", (unsigned long)objects.count);

            if (objects.count == 0) {
                
                // no user account with that email.  Let's check how best to notify them
                if ([MFMessageComposeViewController canSendText] && [MFMailComposeViewController canSendMail]) {
                
                    // offer to send an invite using both SMS & email
                    UIAlertView *alertView = [[UIAlertView alloc]
                                          initWithTitle:NSLocalizedStringWithDefaultValue(@"INVITE_TITLE", nil, [NSBundle mainBundle], @"Recipient account", nil)
                                          message:NSLocalizedStringWithDefaultValue(@"INVITE_MESSAGE", nil, [NSBundle mainBundle], @"The recipient does not have an account.  Send an invitation to download Snap-Meet", nil)
                                          delegate:self
                                          cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"ERROR_DISMISS", nil, [NSBundle mainBundle], @"Dismiss", nil)
                                          otherButtonTitles:NSLocalizedStringWithDefaultValue(@"INVITE_TEXT", nil, [NSBundle mainBundle], @"Text send", nil), NSLocalizedStringWithDefaultValue(@"INVITE_EMAIL", nil, [NSBundle mainBundle], @"Email send", nil), nil];
                
                    alertView.tag = kAlertViewBoth;                             // sweet new thing I justed learned today!
                    [alertView show];
                
                } else if ([MFMessageComposeViewController canSendText]) {
                    
                    // offer to send an invite using only SMS
                    UIAlertView *alertView = [[UIAlertView alloc]
                                              initWithTitle:NSLocalizedStringWithDefaultValue(@"INVITE_TITLE", nil, [NSBundle mainBundle], @"Recipient account", nil)
                                              message:NSLocalizedStringWithDefaultValue(@"INVITE_MESSAGE", nil, [NSBundle mainBundle], @"The recipient does not have an account.  Send an invitation to download Snap-Meet", nil)
                                              delegate:self
                                              cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"ERROR_DISMISS", nil, [NSBundle mainBundle], @"Dismiss", nil)
                                              otherButtonTitles:NSLocalizedStringWithDefaultValue(@"INVITE_TEXT", nil, [NSBundle mainBundle], @"Text send", nil),
                                              nil];
                    
                    alertView.tag = kAlertViewSMS;
                    [alertView show];
                    
                } else if ([MFMailComposeViewController canSendMail]) {
                    
                    // offer to send an invite using only email
                    UIAlertView *alertView = [[UIAlertView alloc]
                                              initWithTitle:NSLocalizedStringWithDefaultValue(@"INVITE_TITLE", nil, [NSBundle mainBundle], @"Recipient account", nil)
                                              message:NSLocalizedStringWithDefaultValue(@"INVITE_MESSAGE", nil, [NSBundle mainBundle], @"The recipient does not have an account.  Send an invitation to download Snap-Meet", nil)
                                              delegate:self
                                              cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"ERROR_DISMISS", nil, [NSBundle mainBundle], @"Dismiss", nil)
                                              otherButtonTitles:NSLocalizedStringWithDefaultValue(@"INVITE_EMAIL", nil, [NSBundle mainBundle], @"Email send", nil),
                                              nil];
                    
                    alertView.tag = kAlertViewMail;
                    [alertView show];
                    
                } else {
                    
                    NSLog(@"Device is not configured to send email or SMS");
                    // unable to send either SMS or email
                    UIAlertView *alertView = [[UIAlertView alloc]
                                              initWithTitle:NSLocalizedStringWithDefaultValue(@"INVITE_TITLE", nil, [NSBundle mainBundle], @"No recipient account", nil)
                                              message:NSLocalizedStringWithDefaultValue(@"INVITE_MESSAGE", nil, [NSBundle mainBundle], @"The recipient does not have an account and you are unable to send text or email messages.", nil)
                                              delegate:self
                                              cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"ERROR_DISMISS", nil, [NSBundle mainBundle], @"Dismiss", nil)
                                              otherButtonTitles:nil];
                
                    alertView.tag = kAlertViewNone;
                    [alertView show];
                    
                }
                
            }
        }
    }];
    
}

// intercept request to send to to [None] or [Invalid] email
- (void)noEmailHandler {
    
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedStringWithDefaultValue(@"ERROR_TITLE", nil, [NSBundle mainBundle], @"Oops!", nil)
                              message:NSLocalizedStringWithDefaultValue(@"INVITE_UNSELECTED", nil, [NSBundle mainBundle], @"No recipient has been selected from your address book.", nil)
                              delegate:nil
                              cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"ERROR_DISMISS", nil, [NSBundle mainBundle], @"Dismiss", nil)
                              otherButtonTitles:nil, nil];
    [alertView show];
    
}

// send the invitation to non-users via email
- (void)sendEmailMessage:(NSArray *)emailRecipients {
    
    if ([MFMailComposeViewController canSendMail]) {
        
        MFMailComposeViewController *mailComposer;
        mailComposer  = [[MFMailComposeViewController alloc] init];
        
        mailComposer.mailComposeDelegate = self;
        
        [mailComposer setModalPresentationStyle:UIModalPresentationFormSheet];
        [mailComposer setToRecipients:emailRecipients];
        [mailComposer setSubject:NSLocalizedStringWithDefaultValue(@"INVITE_SUBJECT", nil, [NSBundle mainBundle], @"SnapMeet Shared", nil)];
        [mailComposer setMessageBody:NSLocalizedStringWithDefaultValue(@"INVITE_BODY", nil, [NSBundle mainBundle], @"Download from App Store: itms-apps://itunes.apple.com/us/app/snap-meet/id870848511?mt=8&uo=4", nil) isHTML:NO];
        
        [self presentViewController:mailComposer animated:YES completion:nil];
        
    } else {
        
        // can't send email.  This 'else' condition should not occur as we are checking device capability in -checkRecipientAccount
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedStringWithDefaultValue(@"ERR_EMAIL_TITLE", nil, [NSBundle mainBundle], @"Unable to Send", nil)
                                  message:NSLocalizedStringWithDefaultValue(@"ERR_EMAIL_MESSAGE", nil, [NSBundle mainBundle], @"Your device is not set to send emails.", nil)
                                  delegate:nil
                                  cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"ERROR_DISMISS", nil, [NSBundle mainBundle], @"Dismiss", nil)
                                  otherButtonTitles:nil, nil];
        
        [alertView show];
    }
}

// send the invitation to non-users via SMS
- (void)sendTextMessage:(NSArray *)textRecipients {
    
    if ([MFMessageComposeViewController canSendText]) {
    
        MFMessageComposeViewController *textComposer;
        textComposer  = [[MFMessageComposeViewController alloc] init];
        
        textComposer.messageComposeDelegate = self;
        
        [textComposer setModalPresentationStyle:UIModalPresentationFormSheet];
        [textComposer setRecipients:textRecipients];

        // uncomment next line for iOS 7.1
        [textComposer setSubject:NSLocalizedStringWithDefaultValue(@"INVITE_SUBJECT", nil, [NSBundle mainBundle], @"SnapMeet Shared", nil)];
        [textComposer setBody:NSLocalizedStringWithDefaultValue(@"INVITE_BODY", nil, [NSBundle mainBundle], @"Download from App Store: itms-apps://itunes.apple.com/us/app/snap-meet/id870848511?mt=8&uo=4", nil)];
        
        [self presentViewController:textComposer animated:YES completion:nil];
        
    } else {
        
        // can't send SMS.   This 'else' condition should not occur as we are checking device capability in -checkRecipientAccount
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedStringWithDefaultValue(@"ERR_TEXT_TITLE", nil, [NSBundle mainBundle], @"Unable to Send", nil)
                                  message:NSLocalizedStringWithDefaultValue(@"ERR_TEXT_MESSAGE", nil, [NSBundle mainBundle], @"Your device is not set to send texts.", nil)
                                  delegate:nil
                                  cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"ERROR_DISMISS", nil, [NSBundle mainBundle], @"Dismiss", nil)
                                  otherButtonTitles:nil, nil];
        
        [alertView show];
    }
}



- (void)sendPushNotification {
    
    // added 6-18-14
    if (!self.recipientEmail) {
        return;
    }
    
    // Build the notification message.  While the Parse max is about 200, I've chosen to limit it to 100 characters.
    // More info on iOS & Parse message length limitations: https://parse.com/questions/maximum-length-of-a-push-notification-for-ios-devices
    
    NSMutableString *notifyMessage = [[NSMutableString alloc] initWithCapacity:100];

    if (self.deviceName.length > 3) {
        
        // There is a device name defined, let use this first.
        if (self.deviceName.length < 50) {
            
            [notifyMessage appendString:self.deviceName];
            [notifyMessage appendString:NSLocalizedStringWithDefaultValue(@"PUSH_MESSAGE", nil, [NSBundle mainBundle], @" is sharing a location.", nil)];
            
        } else {
            
            // device name is too long so let's concatenate and form a shorter message
            [notifyMessage appendString:[self.deviceName substringToIndex:50]];
            [notifyMessage appendString:NSLocalizedStringWithDefaultValue(@"PUSH_MESSAGE", nil, [NSBundle mainBundle], @" is sharing a location.", nil)];
        }
        
    }
    else {
        
        // there is no device name available, let's use the email address instead
        if (currentUser.username.length < 50) {
        
            [notifyMessage appendString:currentUser.username];
            [notifyMessage appendString:NSLocalizedStringWithDefaultValue(@"PUSH_MESSAGE", nil, [NSBundle mainBundle], @" is sharing a location.", nil)];
    
        } else {
        
            // email address is too long so let's concatenate and form a shorter message
            [notifyMessage appendString:[currentUser.username substringToIndex:50]];
            [notifyMessage appendString:NSLocalizedStringWithDefaultValue(@"PUSH_MESSAGE", nil, [NSBundle mainBundle], @" is sharing a location.", nil)];
        }
        
    }
        
    // Build a query to notify recipient of shared location
    NSDictionary *notificationData = [NSDictionary dictionaryWithObjectsAndKeys:
                                      notifyMessage, @"alert",
                                      @"Increment", @"badge",
                                      @"chord.m4r", @"sound",
                                      nil];
    
    // debug since adding FB integration
//    NSLog(@"MapVC: [PUSH] ... push notification user email: [%@]", self.recipientEmail);
    
    // create our installation query
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKey:@"userEmail" equalTo:self.recipientEmail];
    
    // Set the push notification
    PFPush *push = [[PFPush alloc] init];
    [push setQuery:pushQuery];
    [push setData:notificationData];
    
    // set the expiration
    NSTimeInterval timeInterval = 2160.0;
    [push expireAfterTimeInterval:timeInterval];
    
    [push sendPushInBackground];
    
}

// grab a copy of the map view to save an icon for the recipient.  http://stackoverflow.com/questions/10585073/load-mkmapview-in-background-and-create-uiimage-from-it-iphone-ipad
- (UIImage *)renderToImage:(MKMapView *)mapView
{
    UIGraphicsBeginImageContext(mapView.bounds.size);

    // uncomment next line for iOS 7.1
    [mapView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

// resize method used for map and snapshot resize
- (UIImage *)resizeImage:(UIImage *)image toWidth:(float)width andHeight:(float)height {
    // define rectangle
    CGSize newSize = CGSizeMake(width, height);
    CGRect newRectangle = CGRectMake(0, 0, width, height);
    UIGraphicsBeginImageContext(newSize);
    
    [image drawInRect:newRectangle];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resizedImage;
}

// method used to retrieve a Gravatar image using an email address
- (void)retrieveGravatar {
    
    if (!self.recipientEmail) {
        return;
    }
    
    // look to Gravatar to see if an image is available, and if so update the avatarView.image
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // code
        // 1. do basic cleanup of email format
        NSString *cleanedEmail = [self.recipientEmail stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        // 2. create md5 hash
        NSURL *gravatarURL = [GravatarUrlBuilder getGravatarUrl:cleanedEmail];

        // 3. make gravatar call
        NSData *imageData = [NSData dataWithContentsOfURL:gravatarURL];

        // update images on completion message, but only if the imageData is not nil
        if (imageData != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // 4. display image
                self.avatarView.image = [UIImage imageWithData:imageData];
            });
        }
    });
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

// use:  NSString *snipVerb = [self getSnippetContaining:@"get" inString:userText numberOfWords:1];
- (NSString *)getSnippetContaining:(NSString *)keyword
                          inString:(NSString *)theString
                       separatedBy:(NSString *)theSeparator
                     numberOfWords:(NSUInteger)wordCount
{
    int keywordLength = (int)keyword.length;
    NSRange range = [theString rangeOfString:keyword
                                     options:NSBackwardsSearch
                                       range:NSMakeRange(0, theString.length)];
    if (range.location == NSNotFound) {
        return nil;
    }
    
    // pull the next word.  Will need to do some error checking on this (location+keyworkLength bounds)
    NSString *substring = [theString substringFromIndex:range.location+keywordLength];
    NSArray *words = [substring componentsSeparatedByString:theSeparator];
    if (wordCount > words.count) {
        wordCount = words.count;
    }
    NSArray *snippetWords = [words subarrayWithRange:NSMakeRange(0, wordCount)];
    NSString *snippet = [snippetWords componentsJoinedByString:@" "];
    
    return snippet;
}

@end

#pragma mark - Notes

/*  Andrew's code to multi-thread:
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // code
    });
*/

