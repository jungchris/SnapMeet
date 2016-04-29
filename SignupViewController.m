//
//  SignupViewController.m
//  Snap Meet
//
//  Created by chris on 1/14/14.
//  Copyright (c) 2014 Chris Jungmann. All rights reserved.
//

#import "SignupViewController.h"
#import <Parse/Parse.h>
#import "LoginViewController.h"             // for delegate 3-18-14

@interface SignupViewController ()

@end

@implementation SignupViewController

@synthesize delegate;                       // L0ginViewController delegate


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // add a back button
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:@"< Back" style:UIBarButtonItemStylePlain target:self action:@selector(selectorBackTouch)];
    self.navigationItem.leftBarButtonItem = leftButton;
    
    // activity indicator
    [_activityIndicator hidesWhenStopped];
    
    // set button border color
    self.signupButtonOutlet.layer.borderColor = [[UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:0.5] CGColor];
    self.signupButtonOutlet.backgroundColor   = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:0.1];
}

#pragma mark - Button methods

- (void)selectorBackTouch {
    
    [self.navigationController popViewControllerAnimated:YES];    
}

- (IBAction)signupButton:(id)sender {
    
    // get user data entered in text fields and save them.  Use basic string cleanup trimming.
    
    NSString *userEmail = [self.emailField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSString *userPassword = [self.passwordField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *userName = [self.nameField.text stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
//    NSLog(@"userEmail: %@", userEmail);
//    NSLog(@"userPassword: %@", userPassword);
//    NSLog(@"userName: %@", userName);
    
    if (![self isStringValidEmail:userEmail]) {
        
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedStringWithDefaultValue(@"ERROR_TITLE", nil, [NSBundle mainBundle], @"Oops!", nil)
                                  message:NSLocalizedStringWithDefaultValue(@"LOGIN_ERR_EMAIL", nil, [NSBundle mainBundle], @"Need to enter a valid email.", nil)
                                  delegate:nil
                                  cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"ERROR_DISMISS_OK", nil, [NSBundle mainBundle], @"OK", nil)
                                  otherButtonTitles:nil, nil];
        
        [alertView show];
        
    } else if ([userPassword length] < 6) {
        
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedStringWithDefaultValue(@"ERROR_TITLE", nil, [NSBundle mainBundle], @"Oops!", nil)
                                  message:NSLocalizedStringWithDefaultValue(@"LOGIN_ERR_PWD", nil, [NSBundle mainBundle], @"Need to enter a strong password.", nil)
                                  delegate:nil
                                  cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"ERROR_DISMISS_OK", nil, [NSBundle mainBundle], @"OK", nil)
                                  otherButtonTitles:nil, nil];
        
        [alertView show];
        
    } else if ([userName length] < 1) {
        
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedStringWithDefaultValue(@"ERROR_TITLE", nil, [NSBundle mainBundle], @"Oops!", nil)
                                  message:NSLocalizedStringWithDefaultValue(@"LOGIN_ERR_NAME", nil, [NSBundle mainBundle], @"Please enter your name, or nickname.", nil)
                                  delegate:nil
                                  cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"ERROR_DISMISS_OK", nil, [NSBundle mainBundle], @"OK", nil)
                                  otherButtonTitles:nil, nil];
        
        [alertView show];
        
    } else {
        
        PFUser *newUser  = [PFUser user];
        newUser.username = userEmail;           // using email as username for login
        newUser.password = userPassword;
        newUser.email  = userEmail;             // saving email here too
        newUser[@"firstAndLast"] = userName;    // saving name in custom field
        
        [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            
            // Stop the hourglass here
            [_activityIndicator stopAnimating]; // Hide loading indicator

            if (error) {
                
                // something went wrong during async task.  Read the error that Parse.com sent back and show user
                // create a legible error message
                NSLog(@"... PFuser error");
                
                [self showFormattedError:error];
                
            }
            else {
                
                // Async task completed:  everything's Ok
                // set the installation token for this new user
                [self setInstallToken:userEmail];
                
                // pass the email field back to the MainVC by way of the loginVC
                [delegate sendItemToLoginVC:self signupItem:userEmail withName:userName];
                
                // go back to main view
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
                
        }];
        
        // any code here will be run right away while user is being created on the Parse backend
        [_activityIndicator startAnimating]; // Start activity indicator
        
    }
    
}

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

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [textField resignFirstResponder];
    return YES;
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{

    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

#pragma mark - Helper methods

// set the installation token on this device for this new user
- (void)setInstallToken:(NSString *)userEmail {
    
    NSLog(@"LoginVC: [TOKEN] setInstallToken with email: %@", userEmail);
    // Create a record of the current installation for this user.  This will later be used for individual push notifications
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


@end

