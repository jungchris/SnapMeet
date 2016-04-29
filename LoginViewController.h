//
//  LoginViewController.h
//  Snap Meet
//
//  Created by chris on 1/14/14.
//  Copyright (c) 2014 Chris Jungmann. All rights reserved.
//
@class LoginViewController;

// delegate implemented in MainViewController
@protocol LoginViewControllerDelegate <NSObject>

- (void)loginViewHandler:(LoginViewController *)lvc handleObject:(id)object;

//- (void)loginViewHandlerForFB:(LoginViewController *)lvc handleObject:(id)object;

// intermediary delegate to pass SignupVC info to MainVC
- (void)sendItemToMainVC:(LoginViewController *)lvc signupItem:(NSString*)email withName:(NSString*)name;

@end

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "SignupViewController.h"        // for delegate

@interface LoginViewController : UIViewController <UITextFieldDelegate, SignupViewControllerDelegate>

@property (weak, nonatomic) id<LoginViewControllerDelegate> delegate;

// user input fields
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;

// facebook activity indicator
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (weak, nonatomic) IBOutlet UIButton *loginButtonOutlet;
@property (weak, nonatomic) IBOutlet UIButton *signupButtonOutlet;


- (IBAction)loginButtonFB:(id)sender;
- (IBAction)loginButton:(id)sender;
- (IBAction)signupButton:(id)sender;
- (IBAction)privacyButton:(id)sender;       // privacy notification message

@end

