//
//  MainViewController.h
//  ShareMySpot
//
//  Created by chris on 1/14/14.
//  Copyright (c) 2014 Chris Jungmann. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <AddressBookUI/AddressBookUI.h>

#import "MapViewController.h"
#import "JSCustomBadge.h"
#import "LocationsViewController.h"
#import "AppDelegate.h"                 // for global iAd
#import "LoginViewController.h"         // for delegate
#import "LocationsViewController.h"     // for delegate
#import "SettingsViewController.h"

#define SharedAdBannerView ((AppDelegate *)[[UIApplication sharedApplication] delegate]).adBanner


@interface MainViewController : UIViewController <ABPeoplePickerNavigationControllerDelegate, ADBannerViewDelegate, LoginViewControllerDelegate, LocationsViewControllerDelegate>

// properties describing the push recipient
@property (strong, nonatomic) NSString *recipientEmail;
@property (strong, nonatomic) NSString *recipientName;
@property (strong, nonatomic) NSData *recipientMugshot;     // added 3-10-14
@property (strong, nonatomic) NSString *recipientPhone;     // for SMS

// properties decribing the locations being shared by others
@property (strong, nonatomic) NSMutableArray *locationsArray;

// set the PFUser currentUser property for use in willLoad and didLoad
@property (strong, nonatomic) PFUser *currentUser;

// set the current user's properties
@property (strong, nonatomic) NSString *currentUserName;
@property (strong, nonatomic) NSString *currentUserEmail;
@property (strong, nonatomic) NSString *currentUserURL;

//// set the user's email and name for common usage with FB
//@property (strong, nonatomic) NSString *currentFBUserName;
//@property (strong, nonatomic) NSString *currentFBUserEmail;
//@property (strong, nonatomic) NSString *currentFBUserURL;

// display items
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

// Display badge and hide the subview when logging back in 2-11-14
@property (strong, nonatomic) JSCustomBadge *badge;

// button methods
- (IBAction)logoutButton:(id)sender;
- (void)shareLocation:(id)sender;
- (void)findFriends:(id)sender;
- (void)loadAddressBook:(id)sender;
- (void)loadSettings:(id)sender;

// custom button properties to be defined in methodsa
@property (strong, nonatomic) UIButton *shareButton;
@property (strong, nonatomic) UIButton *friendsButton;
@property (strong, nonatomic) UIButton *addressBookButton;
@property (strong, nonatomic) UIButton *settingsButton;

// workaround for iOS 7.0.03 iPhone 4,4S crash
+ (ABPeoplePickerNavigationController *)sharedPeoplePicker;

// method invoked by LoginViewController
- (void)enterForegroundHandler;

// method to do some RFC checking of email format
-(BOOL) isStringValidEmail:(NSString *)checkString;

@end

//  Question:  Why is this working using <ABPersonViewControllerDelegate> instead of <ABPeoplePickerNavigationControllerDelegate> ?
