//
//  LoginViewController.m
//  Snap Meet
//
//  Created by chris on 1/14/14.
//  Copyright (c) 2014 Chris Jungmann. All rights reserved.
//

#import "LoginViewController.h"
#import "MainViewController.h"              // added to be able to invoke delegate on completion 3-1-14

#import <Parse/Parse.h>


@interface LoginViewController ()

@end

@implementation LoginViewController

@synthesize delegate;                   // L0ginViewController delegate


- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// hide the back button on the login view
    self.navigationItem.hidesBackButton = YES;
    
    // activity indicator
    [_activityIndicator hidesWhenStopped];
    
    // set button border and background color
    self.loginButtonOutlet.layer.borderColor = [[UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:0.6] CGColor];
    self.loginButtonOutlet.backgroundColor   = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:0.5];
    
    self.signupButtonOutlet.layer.borderColor = [[UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:0.6] CGColor];
    self.signupButtonOutlet.backgroundColor   = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:0.5];
    
}

#pragma mark - Button methods


// direct login
- (IBAction)loginButton:(id)sender {
    
    // get user data entered in text fields and save them.  Use basic string cleanup trimming.
    NSString *userEmail = [self.emailField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                            
    NSString *userPassword = [self.passwordField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // Todo ensure that something has been entered in the email & password field
    if ([userEmail length] == 0 || [userPassword length] == 0) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedStringWithDefaultValue(@"ERROR_TITLE", nil, [NSBundle mainBundle], @"Oops!", nil)
                                  message:NSLocalizedStringWithDefaultValue(@"LOGIN_ERR_EMAIL", nil, [NSBundle mainBundle], @"Need email address and password", nil)
                                  delegate:nil
                                  cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"ERROR_DISMISS_OK", nil, [NSBundle mainBundle], @"OK", nil)
                                  otherButtonTitles:nil, nil];
        
        [alertView show];
        
    }
    else {
        
        // logging in
        [PFUser logInWithUsernameInBackground:userEmail password:userPassword block:^(PFUser *user, NSError *error) {
            
            [_activityIndicator stopAnimating]; // Hide loading indicator on completion
            
            if (error) {
                
                NSLog(@"... LoginVC: PFuser error");
                
                // something went wrong during async task.  Read the error that Parse.com sent back and show user
                [self showFormattedError:error];
                
            }
            else {
                
                // set device installation token for push notifications
                [self setInstallToken:userEmail];
                
                // call the M-ainViewController delegates to set the user info properties and update locations
                
                // TODO: Retrieve userName from Parse
                NSString *userName = [user objectForKey:@"firstAndLast"];
                // NSLog(@"user firstAndLast: %@", userName);
                
                if (userName.length > 1 && userEmail.length > 6) {
                    
//                    NSLog(@"===> LoginVC:loginButton");
//                    NSLog(@"... userName %@", userName);
//                    NSLog(@"... userEmail %@", userEmail);
                    
                    NSArray *userArray = [[NSArray alloc] initWithObjects:[userEmail copy], [userName copy], nil];
                    [delegate loginViewHandler:self handleObject:userArray];
                    
                } else if (userEmail.length > 6) {
                    
                    // No name, let's get device name in lieu of user name
                    NSString *deviceName = [[UIDevice currentDevice] name];
                    
                    if (deviceName) {
                    
                        NSArray *userArray = [[NSArray alloc] initWithObjects:[userEmail copy], deviceName, nil];
                        [delegate loginViewHandler:self handleObject:userArray];
                        
                    } else {
                     
                        NSArray *userArray = [[NSArray alloc] initWithObjects:[userEmail copy], nil];
                
                        [delegate loginViewHandler:self handleObject:userArray];
                    }
                    
                } else {
                    
                    NSLog(@"LoginVC: l0ginButton [call] ERROR no userEmail");
                }
                
                [self.navigationController popToRootViewControllerAnimated:YES];
                
            }
            
        }];
        
        [_activityIndicator startAnimating]; // Show loading indicator until login is finished

    }
}

// sign-up button
- (IBAction)signupButton:(id)sender {
    
    // user needs to create an account
    [self performSegueWithIdentifier:@"showSignup" sender:self];
    
}

// facebook login
- (IBAction)loginButtonFB:(id)sender {
    
    // Set permissions required from the facebook user account
//    NSArray *permissionsArray = @[ @"public_profile", @"email", @"user_friends"];
    NSArray *permissionsArray = @[ @"public_profile", @"email"];
    
    // Login PFUser using facebook
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        
        [_activityIndicator stopAnimating]; // Hide loading indicator
        
        if (!user) {
            if (!error) {
                NSLog(@"LoginVC: Error: The user cancelled the Facebook login.");
                
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:NSLocalizedStringWithDefaultValue(@"FBLOGIN_ERR_TITLE", nil, [NSBundle mainBundle], @"Login error", nil)
                                      message:NSLocalizedStringWithDefaultValue(@"FBLOGIN_ERR_MESSAGE", nil, [NSBundle mainBundle], @"Facebook login was cancelled", nil)
                                      delegate:nil
                                      cancelButtonTitle:nil
                                      otherButtonTitles:NSLocalizedStringWithDefaultValue(@"ERROR_DISMISS", nil, [NSBundle mainBundle], @"Dismiss", nil), nil];
                [alert show];
                
            } else {
                
                NSLog(@"LoginVC: Error: An problem occurred: %@", error);
                
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Error" message:@"Your connection to the Internet appears to be offline.  Please check that you are not in airplane mode." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
//                [alert show];

                [self showFormattedError:error];
                
                // Ok, so we have some problems, let's try this ...
                if( ![PFFacebookUtils session] ) {
                    
                    [PFFacebookUtils linkUser:[PFUser currentUser] permissions:permissionsArray block:^(BOOL succeeded, NSError *error) {
                        //do work here
                        if (!error) {
    
                            NSLog(@"LoginVC: Session Invalid: User Linked");
                            
                            [self retrieveUserInfoFromFB];
                            
                        } else {
                            
                            NSLog(@"LoginVC: Session Invalid: Error linking");
                            [self showFormattedError:error];
                            
                        }
                    }];
                    
                } else {
                    
                    // error recovery, try to re-authorize user
                    NSLog(@"LoginVC: Valid Session: closing session, try to reauthorize user!");
                    
                    [PFUser logOut];
                    [[PFFacebookUtils session] close];
                    
                    [PFFacebookUtils linkUser:[PFUser currentUser] permissions:permissionsArray block:^(BOOL succeeded, NSError *error) {
                        //do work here
                        if (!error) {
                            
                            NSLog(@"LoginVC: User Linked ... reauthorizing");
                            
                            [PFFacebookUtils reauthorizeUser:[PFUser currentUser] withPublishPermissions:permissionsArray audience:FBSessionDefaultAudienceNone block:^(BOOL succeeded, NSError *error) {
                            }];
                            
                            [self retrieveUserInfoFromFB];
                            
                        } else {
                            
//                            NSLog(@"LoginVC: Error linking");
                            [self showFormattedError:error];
                            
                        }
                    }];
                }
            }
        } else if (user.isNew) {
//            NSLog(@"LoginVC: New user with facebook signed up and logged in!");
            [self retrieveUserInfoFromFB];
            
        } else {
//            NSLog(@"LoginVC: User with facebook logged in!");
            [self retrieveUserInfoFromFB];
            
        }
    }];
    
    [_activityIndicator startAnimating]; // Show loading indicator until login is finished
    
}

// display provacy notice on demand
- (IBAction)privacyButton:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedStringWithDefaultValue(@"PRIVACY_TITLE", nil, [NSBundle mainBundle], @"Privacy Notice", nil)
                              message:NSLocalizedStringWithDefaultValue(@"PRIVACY_MESSAGE", nil, [NSBundle mainBundle], @"We do not collect information about you for any purpose other than as needed for this app to function.", nil)
                              delegate:nil
                              cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"ERROR_DISMISS_OK", nil, [NSBundle mainBundle], @"OK", nil)
                              otherButtonTitles:nil, nil];
    
    [alertView show];
}

#pragma mark - Delegates

// remove the keyboard
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [textField resignFirstResponder];
    return YES;
    
}

// listen for a touch event outside the keyboard space
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{

    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

// In prep for segue set the destination view's property for email
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"showSignup"]) {
        
        // instantiate the SignupViewController delegate here
        SignupViewController *signupViewController = [segue destinationViewController];
        signupViewController.delegate = self;

    }
}

// this intermediary delegate passes the email received from the SignupVC back to the MainVC
- (void)sendItemToLoginVC:(SignupViewController *)svc signupItem:(NSString *)email withName:(NSString *)name {
    
    [delegate sendItemToMainVC:self signupItem:email withName:name];
}


#pragma mark - Helper methods

- (void)retrieveUserInfoFromFB {
    
//    NSLog(@"LoginVC: retreiveUserInfoFromFB");
    
    // Send request to Facebook
    FBRequest *request = [FBRequest requestForMe];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        // handle response
        if (!error) {
            // Parse the data received
            NSDictionary *userData = (NSDictionary *)result;
            NSString *facebookID = userData[@"id"];
            
            NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
            
            NSMutableDictionary *userProfile = [NSMutableDictionary dictionaryWithCapacity:5];
            
            NSMutableString *userName = [[NSMutableString alloc] initWithCapacity:254];
            NSMutableString *userEmail = [[NSMutableString alloc] initWithCapacity:254];
            NSMutableString *userURL = [[NSMutableString alloc] initWithCapacity:254];
            
            if (facebookID) {
                userProfile[@"facebookId"] = facebookID;
            }
            
            if (userData[@"name"]) {
                userProfile[@"name"] = userData[@"name"];
                userName = userData[@"name"];
                
                // this propery will be set in [[PFUser currentUser] saveInBackground] below 3-31-14
                [[PFUser currentUser] setObject:userName forKey:@"firstAndLast"];
            }
            
            if (userData[@"location"][@"name"]) {
                userProfile[@"location"] = userData[@"location"][@"name"];
            }
            
            // make sure you have email before setting install token
            if (userData[@"email"]) {
                userProfile[@"email"] = userData[@"email"];
                userEmail = userData[@"email"];
                
                // this propery will be set in [[PFUser currentUser] saveInBackground] below 3-31-14
                [[PFUser currentUser] setObject:userEmail forKey:@"email"];
                
                // set the installation token with email
                [self setInstallToken:userData[@"email"]];
            }
            
            
            
            if ([pictureURL absoluteString]) {
                userURL = [[pictureURL absoluteString] copy];
                userProfile[@"pictureURL"] = userURL;
            }
            
            // prepare for delegate calls
            // make the login view handler delegate call in MainViewController
            if (userEmail && userName && userURL) {
                
//                NSLog(@"LoginVC: [call] loginViewHandler delegate with userEmail, userName, userURL");
                NSArray *userArray = [[NSArray alloc] initWithObjects:[userEmail copy], [userName copy], [userURL copy], nil];
                [delegate loginViewHandler:self handleObject:userArray];
            }
            else if (userEmail && userName) {
                
//                NSLog(@"LoginVC: [call] loginViewHandler delegate with userEmail and userName");
                NSArray *userArray = [[NSArray alloc] initWithObjects:[userEmail copy], [userName copy], nil];
                [delegate loginViewHandler:self handleObject:userArray];
            }
            else if (userEmail) {

//                NSLog(@"LoginVC: [call] loginViewHandler delegate with userEmail");
                NSArray *userArray = [[NSArray alloc] initWithObjects:[userEmail copy], nil];
                [delegate loginViewHandler:self handleObject:userArray];
            } else {
                
                NSLog(@"---> ERROR: No userEmail in retreiveUerInfoFromFB");
            }
            
            [[PFUser currentUser] setObject:userProfile forKey:@"profile"];
            [[PFUser currentUser] saveInBackground];
            
            // without waiting for asnc task to complete return to main view
            [self.navigationController popToRootViewControllerAnimated:YES];
            
        } else if ([[[[error userInfo] objectForKey:@"error"] objectForKey:@"type"]
                    isEqualToString: @"OAuthException"]) { // Since the request failed, we can check if it was due to an invalid session
            NSLog(@"LoginVC: The facebook session was invalidated.  Invoking logout handler");
            [self logoutHandler:nil];
            
        } else {
            
            NSLog(@"LoginVC: Some other error (doing nothing): %@", error);
            [self showFormattedError:error];
            
            [self logoutHandler:nil];
            
        }
    }];
}


- (void)logoutHandler:(id)sender {
    // Logout user, this automatically clears the cache
    [PFUser logOut];
    
    // Return to login view controller
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)setInstallToken:(NSString *)userEmail {
    
    // NSLog(@"LoginVC: [TOKEN] setInstallToken with email: %@", userEmail);
    // Create a record of the current installation for this user.  This will later be user for individual push notifications
    [[PFInstallation currentInstallation] setObject:[PFUser currentUser] forKey:@"userId"];
    [[PFInstallation currentInstallation] setObject:userEmail forKey:@"userEmail"];
    [[PFInstallation currentInstallation] saveEventually];
    
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

#pragma mark - Notes

/* Badge not resetting:
 https://www.parse.com/questions/pfinstallation-saveeventually-is-not-resetting-the-badge-number-from-server
 PFInstallation *currentInstallation = [PFInstallation currentInstallation];
 if (currentInstallation.badge != 0) {
 currentInstallation.badge = 0;
 [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
 if (error) {
 [currentInstallation saveEventually];
 }
 }];
 }
 */


@end
