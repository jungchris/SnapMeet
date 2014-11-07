//
//  DetailViewController.m
//  Snap Meet
//
//  Created by chris on 3/12/14.
//  Copyright (c) 2014 Chris Jungmann. All rights reserved.
//

#import "DetailViewController.h"
#import "AppDelegate.h"
#import "LocationsViewController.h"         // added 3-14-14 to implement delegate

@interface DetailViewController ()

@end

@implementation DetailViewController

@synthesize delegate;                       // LocationViewController delegate


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
//    NSLog(@"DetailVC: viewDidLoad location row = %li", (long)self.locationRow);
    
    if (self.selectedLocation) {
    
        NSString *senderName     = [self.selectedLocation objectForKey:@"senderName"];
        NSString *senderDevice   = [self.selectedLocation objectForKey:@"senderDevice"];
        PFFile   *senderMapFile  = [self.selectedLocation objectForKey:@"mapFile"];
        PFFile   *senderSnapFile = [self.selectedLocation objectForKey:@"snapFile"];

        // set nameLabel
        if (senderName.length > 0) {
            
            NSMutableString *nameText = [[NSMutableString alloc] initWithCapacity:60];
            [nameText appendString:NSLocalizedStringWithDefaultValue(@"SENT_BY", nil, [NSBundle mainBundle], @"Sent by: ", nil)];
            [nameText appendString:senderName];
            self.nameLabel.text = nameText;
            
        } else if (senderDevice.length > 0) {
            
            NSMutableString *nameText = [[NSMutableString alloc] initWithCapacity:60];
            [nameText appendString:NSLocalizedStringWithDefaultValue(@"SENT_BY", nil, [NSBundle mainBundle], @"Sent by: ", nil)];
            [nameText appendString:senderDevice];
            self.nameLabel.text = nameText;
            
        } else {
            self.nameLabel.text = NSLocalizedStringWithDefaultValue(@"DEFAULT_NONAME", nil, [NSBundle mainBundle], @"No sender name specified", nil);
        }
        
        // set timeLabel
        NSDate *updated = [self.selectedLocation updatedAt];
        if (updated) {
            // convert format
            NSMutableString *detailText = [[NSMutableString alloc] initWithCapacity:60];
            [detailText appendString:NSLocalizedStringWithDefaultValue(@"TIME_SENT", nil, [NSBundle mainBundle], @"Sent at: ", nil)];
            [detailText appendString:[NSDateFormatter localizedStringFromDate:updated dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle]];
        
            self.timeLabel.text = detailText;
        } else {
            self.timeLabel.text = NSLocalizedStringWithDefaultValue(@"DEFAULT_NOTIME", nil, [NSBundle mainBundle], @"No time specified", nil);
        }

        // set the map view
        if (senderMapFile != NULL) {
            
            NSURL *mapFileUrl = [[NSURL alloc] initWithString:senderMapFile.url];
            NSData *mapData = [NSData dataWithContentsOfURL:mapFileUrl];
            // set the primary and fallback image used to display the map
            self.mapView.layer.masksToBounds = YES;            // noted no difference
            [self.mapView.layer setBorderColor:[[UIColor grayColor] CGColor]];
            [self.mapView.layer setBorderWidth: 1.0f];
            if (mapData) {
                // display the map saved on Parse
                self.mapView.image = [UIImage imageWithData:mapData];
            } else {
                // display an icon as fallback
                self.mapView.image = [UIImage imageNamed:@"icon_map"];
            }
        }

        // set the snapshot view
        if (senderSnapFile != NULL) {
            
            NSURL *snapFileUrl = [[NSURL alloc] initWithString:senderSnapFile.url];
            NSData *snapData = [NSData dataWithContentsOfURL:snapFileUrl];
            // set the primary and fallback image used to display the snapshot
            self.snapView.layer.masksToBounds = YES;            // noted no difference
            [self.snapView.layer setBorderColor:[[UIColor grayColor] CGColor]];
            [self.snapView.layer setBorderWidth: 1.0f];
            if (snapData) {
                // display the map saved on Parse
                UIImage *snapImage = [UIImage imageWithData:snapData];
                
                // check image orientation
                if (snapImage.imageOrientation == UIImageOrientationUp) {
                    NSLog(@" ---> portrait");
                    
                    self.snapView.frame = self.view.bounds;
                    self.snapView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
                    self.snapView.contentMode = UIViewContentModeScaleAspectFill;
                    
                } else if (snapImage.imageOrientation == UIImageOrientationLeft || snapImage.imageOrientation == UIImageOrientationRight || snapImage.imageOrientation == UIImageOrientationLeftMirrored || snapImage.imageOrientation == UIImageOrientationRightMirrored) {
                    
                    NSLog(@" ---> landscape");
                }
                self.snapView.image = [UIImage imageWithData:snapData];
                
            } else {
                // display an icon as fallback
                self.snapView.image = [UIImage imageNamed:@"icon_person"];
            }
        }
    }
    
    // start iAd on this view
    [self addADBannerViewToBottom];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ADBanner delegates

- (void)bannerViewDidLoadAd:(ADBannerView *)banner {
    [SharedAdBannerView setHidden:NO];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
    [SharedAdBannerView setHidden:YES];
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner {
    NSLog(@"MapVC: Delegate: bannerViewActionDidFinish");
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


#pragma mark Button methods

- (IBAction)navitageButton:(id)sender {
    
    // delete row using delegate in MainVC
    [delegate detailViewRowDelete:self deleteItem:self.locationRow];
    
    [self removeADBannerView];
    
    [self showMap];
    
    // return to root view
    [self.navigationController popToRootViewControllerAnimated:YES];
    
}

- (IBAction)deleteButton:(id)sender {
    
    // cleanup: delete the location as requested by user
    [self.selectedLocation deleteInBackground];
    
    // decrement the locations counter
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.locationsCount = appDelegate.locationsCount - 1;
    
    // Decrement the badge count
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    
    if (currentInstallation.badge > 0) {
        
        currentInstallation.badge--;
        [currentInstallation saveEventually];
    }
    
    // delete row using delegate in MainVC
    [delegate detailViewRowDelete:self deleteItem:self.locationRow];
    
    [self removeADBannerView];
    [self.navigationController popToRootViewControllerAnimated:YES];

}

#pragma mark - Helper methods

- (void)showMap {
    
    // extract the longitude and latitude from the comma delimited string Parse object
    NSString *gpsString = [self.selectedLocation objectForKey:@"gpsCoordinate"];
    NSArray *subStrings = [gpsString componentsSeparatedByString:@","];
    NSString *longitudeString = [subStrings objectAtIndex:0];
    NSString *latitudeString = [subStrings objectAtIndex:1];
    
    NSLog(@"longString %@", longitudeString);
    NSLog(@"latString %@", latitudeString);
    
    // make sure you don't have empty strings
    if (latitudeString.length > 5 && longitudeString.length > 5) {
        
        // Create an MKMapItem to pass to the Maps app
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([longitudeString doubleValue], [latitudeString doubleValue]);
        
        // Convert the CLPlacemark to an MKPlacemark
        MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil];
        MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
        //    [mapItem setName:@"Destination"];
        
        // Can use MKLaunchOptionsDirectionsModeWalking instead
        NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
        
        // cleanup: delete the location now because we won't be getting back to the app when Map launched
        [self.selectedLocation deleteInBackground];
        
        // decrement the locations counter
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        appDelegate.locationsCount = appDelegate.locationsCount - 1;
        
        // Decrement the badge count
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        
        if (currentInstallation.badge > 0) {
            
            currentInstallation.badge--;
            [currentInstallation saveEventually];
        }
        
        [self removeADBannerView];
        
        // Let's load the instance openInMapsWithLaunchOptions instead
        [mapItem openInMapsWithLaunchOptions:launchOptions];
        
    } else {
        // handle lack of latitude OR longitude by deleting the record and notifying user
        [self.selectedLocation deleteInBackground];
        
        // decrement the locations counter
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        appDelegate.locationsCount = appDelegate.locationsCount - 1;
        // Decrement the badge count
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        if (currentInstallation.badge > 0) {
            currentInstallation.badge--;
            [currentInstallation saveEventually];
        }
        
        // delete row using delegate in MainVC
        [delegate detailViewRowDelete:self deleteItem:self.locationRow];
        
        // no GPS info
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedStringWithDefaultValue(@"ERR_TITLE_NOGPSINFO", nil, [NSBundle mainBundle], @"No Location", nil)
                                  message:NSLocalizedStringWithDefaultValue(@"ERR_TITLE_NOGPSINFO", nil, [NSBundle mainBundle], @"Sender did not include their GPS location.", nil)
                                  delegate:nil
                                  cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"ERROR_DISMISS", nil, [NSBundle mainBundle], @"Dismiss", nil)
                                  otherButtonTitles:nil, nil];
        
        [alertView show];
        
    }
    
}

@end
