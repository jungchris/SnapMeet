//
//  SignupViewController.h
//  Snap Meet
//
//  Created by chris on 1/14/14.
//  Copyright (c) 2014 Chris Jungmann. All rights reserved.
//

@class SignupViewController;

// delegate implemented in LocationsViewController
@protocol SignupViewControllerDelegate <NSObject>

- (void)sendItemToLoginVC:(SignupViewController *)svc signupItem:(NSString*)email withName:(NSString*)name;

@end

#import <UIKit/UIKit.h>

@interface SignupViewController : UIViewController <UITextFieldDelegate>

// detail view delegate
@property (weak, nonatomic) id<SignupViewControllerDelegate> delegate;

// user input fields
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

@property (weak, nonatomic) IBOutlet UIButton *signupButtonOutlet;

- (IBAction)signupButton:(id)sender;

// activity indicator
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

// privacy notification message for user
- (IBAction)privacyButton:(id)sender;

@end
