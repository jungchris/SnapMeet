//
//  MapViewController.h
//  Snap Meet
//
//  Created by chris on 1/14/14.
//  Copyright (c) 2014 Chris Jungmann. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <Parse/Parse.h>
#import <MobileCoreServices/MobileCoreServices.h>       // 3-10-14

#import <MessageUI/MessageUI.h>                         // 3-31-14

#import "AppDelegate.h"

#define SharedAdBannerView ((AppDelegate *)[[UIApplication sharedApplication] delegate]).adBanner

@interface MapViewController : UIViewController <CLLocationManagerDelegate, MKMapViewDelegate, ADBannerViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, UIAlertViewDelegate>

// this describes the GPS coordinates display
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *currentLocation;

// These properties display info about the recipient on the top of the view
@property (weak, nonatomic) IBOutlet UIImageView *avatarView;
// accessing email and recipient property from AddressViewController
@property (strong, nonatomic) NSString *recipientEmail;
@property (strong, nonatomic) NSString *recipientName;
@property (strong, nonatomic) NSData *recipientImage;
@property (strong, nonatomic) NSString *recipientPhone; // used for SMS

// use this to notify recipient of sender's email & device name
@property (strong, nonatomic) PFUser *currentUser;      // sender object
@property (strong, nonatomic) NSString *deviceName;     // sender's device name
@property (strong, nonatomic) NSString *senderName;
@property (strong, nonatomic) NSString *senderURL;      // sender profile picture from FB
@property (strong, nonatomic) UIImage *mapImage;        // saves a snapshot of the map

// Storyboard connections:
// this describes the Map connection
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

// and the GPS coordinates and email labels on the MapView screen
//@property (weak, nonatomic) IBOutlet UILabel *latitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UILabel *recipientLabel;

// camera properties
@property (strong, nonatomic) UIImagePickerController *photoPicker;
@property (strong, nonatomic) UIImage *snapshot;

// set button properties
@property (weak, nonatomic) IBOutlet UIButton *sendButtonOutlet;
@property (weak, nonatomic) IBOutlet UIButton *cameraButtonOutlet;


//@property (weak, nonatomic) IBOutlet UIImageView *mapIcon; // used to display map icon for testing purposes
- (IBAction)cameraButton:(id)sender;

// This connects to the 'Share/send' button. Use this to make the Parse.com call
- (IBAction)sendLocationButton:(id)sender;

// This connects to the 'Refresh location' button.  Use it to update the GPS location
//- (IBAction)updateCurrentLocation:(id)sender;

// cancel and go back to previous view
- (IBAction)cancelButton:(id)sender;

// helper methods
- (UIImage *)renderToImage:(MKMapView *)mapView;

- (UIImage *)resizeImage:(UIImage *)image toWidth:(float)width andHeight:(float)height;


@end
