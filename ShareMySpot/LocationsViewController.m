//
//  LocationsViewController.m
//  Snap Meet
//
//  Created by chris on 1/17/14.
//  Copyright (c) 2014 Chris Jungmann. All rights reserved.
//

#import "LocationsViewController.h"
#import "LocationTableCell.h"
#import "AppDelegate.h"
#import "GravatarUrlBuilder.h"                  // added 3-11-14 to show Gravatar as fallback

@interface LocationsViewController ()

@end

@implementation LocationsViewController

@synthesize delegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.currentUser = [PFUser currentUser];
    if (!self.currentUser) {
        [self performSegueWithIdentifier:@"showLogin" sender:self];
    }
    
//    NSLog(@"LocationsVC - Current user is: %@", self.currentUser.email);
    
    // need to register nib before using LocationTableCell
    [self.tableView registerNib:[UINib nibWithNibName:@"LocationTableCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"LocationTableCell"];
    
}

- (void) viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    // look for the objects from Parse set in MainViewController viewDidLoad
//    NSLog(@"In LocationsViewController we have %lu locations", (unsigned long)[self.locations count]);

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.locations count];
}

// Uses custom tableView described in LocationTableCell.xib
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *locationTableIdentifier = @"LocationTableCell";
    LocationTableCell *cell = (LocationTableCell *)[tableView dequeueReusableCellWithIdentifier:locationTableIdentifier forIndexPath:indexPath];
    
    // why did I comment this out?  Boy this guy is on a roll!
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"LocationTableCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    // Configure the cell to display the shared locations sender email
//    int reverseRow = (int)(self.locations.count - 1 - indexPath.row);
    PFObject *location = [self.locations objectAtIndex:indexPath.row];
    
    NSString *senderName    = [location objectForKey:@"senderName"];
    NSString *senderDevice  = [location objectForKey:@"senderDevice"];
    NSString *senderEmail   = [location objectForKey:@"senderEmail"];
    NSString *senderURL     = [location objectForKey:@"senderURL"];         // FB mugshot
//    PFFile   *senderMapFile = [location objectForKey:@"mapFile"];           // this holds the PNG file object
    
    if (senderName.length > 0) {
        cell.nameLabel.text = senderName;
    } else if (senderDevice.length > 0) {
        cell.nameLabel.text = senderDevice;
    } else {
        cell.nameLabel.text = NSLocalizedStringWithDefaultValue(@"DEFAULT_NONAME", nil, [NSBundle mainBundle], @"No name", nil);
    }
    
    // because senderEmail will contain an FB indentifier instead for FB login we need to make sure it's acually an email address before displaying
    if ([senderEmail rangeOfString:@"@"].location != NSNotFound) {
        // This appears to be an email address because there's an '@' present
        cell.textLabel.text = senderEmail;
    } else if (senderDevice.length > 0) {
        // display the device name instead
        cell.textLabel.text = senderDevice;
    } else {
        // display backup
        cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"DEFAULT_DEVICE", nil, [NSBundle mainBundle], @"iOS device", nil);
    }
    
    // load the sender's picture.
    if (senderURL.length > 14) {
        
        // The URL has data, so sender's FB picture can be displayed
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // code
        
            // 1. prepare the URL
            NSURL *url = [NSURL URLWithString:senderURL];
        
            // 2. make Facebook call
            NSData *imageData = [NSData dataWithContentsOfURL:url];
        
            // 3. update images on completion message, but only if the imageData is not nil
            if (imageData != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    // 4. display image
                    cell.iconImage.image = [UIImage imageWithData:imageData];
                });
            }
        });
    
    } else if (senderEmail.length > 7) {
        
        // no FB image so let's look for Gravatar
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // code
            // 1. do basic cleanup of email format
            NSString *cleanedEmail = [senderEmail stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            // 2. create md5 hash
            NSURL *gravatarURL = [GravatarUrlBuilder getGravatarUrl:cleanedEmail];
            
            // 3. make gravatar call
            NSData *imageData = [NSData dataWithContentsOfURL:gravatarURL];
            
            // update images on completion message, but only if the imageData is not nil
            if (imageData != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    // 4. display image
                    cell.iconImage.image = [UIImage imageWithData:imageData];
                });
            }
        });
        
    }
    
    // in case there's no Gravatar & no FB image, we pre-load the map icon instead
//    NSURL *imageFileUrl = [[NSURL alloc] initWithString:senderMapFile.url];
//    NSData *imageData = [NSData dataWithContentsOfURL:imageFileUrl];
//    if (imageData) {
//        // display the map saved on Parse
//        cell.iconImage.image = [UIImage imageWithData:imageData];
//    } else {
//        // by default show map icon.  This gets overwritten by completion blocks
//        cell.iconImage.image = [UIImage imageNamed:@"icon_map"];
//    }

    cell.iconImage.image = [UIImage imageNamed:@"icon_map"];

    // Show a timestamp of the entry - the updatedAt column is a property of each parse object and retreived in this manner instead of using objectForKey
    NSDate *updated = [location updatedAt];
    NSMutableString *detailText = [[NSMutableString alloc] initWithCapacity:60];
    
    NSLog(@"---> updatedAt: %@", updated);
    NSLog(@"---> DateTime localized: %@", [NSDateFormatter localizedStringFromDate:updated dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]);
    
    
    [detailText appendString:NSLocalizedStringWithDefaultValue(@"TIME_SENT", nil, [NSBundle mainBundle], @"Sent: ", nil)];
    [detailText appendString:[NSDateFormatter localizedStringFromDate:updated dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]];
    cell.timeLabel.text = detailText;

    return cell;
}

// return the custom table cell height
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 89;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // display the map with directions (reversed order)
//    int reverseRow = (int)(self.locations.count - 1 - indexPath.row);
    self.selectedLocation = [self.locations objectAtIndex:indexPath.row];
    
    // set the location row to pass row info to DetailVC
    self.locationRow = indexPath.row;
    
    [self performSegueWithIdentifier:@"showDetail" sender:self];
    
}

#pragma mark - Application delegates

// this is an intermediary delegate to send data to MainVC from DetailVC
- (void)detailViewRowDelete:(DetailViewController *)dvc deleteItem:(NSInteger)item {
    
    // the row to delete is sent to mainVC from detailVC in here
    [delegate locationViewRowDelete:self deleteItem:item];

}


#pragma mark - Navigation delegates

// In prep for segue set the destination view's property for email
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"showDetail"]) {
        
        NSLog(@"LocationVC: prepareForSegue: showDetail");
        
        // set emilAddr & rcipientName property in MpViewController
        DetailViewController *dvc = [segue destinationViewController];
        [dvc setSelectedLocation:self.selectedLocation];
        
        // set the indexPath.row
        [dvc setLocationRow:self.locationRow];
        
        // set the delegate
        dvc.delegate = self;
        
    }
}


#pragma mark - Notes

// Getting direction using MKMapView:
// http://nshipster.com/mktileoverlay-mkmapsnapshotter-mkdirections/

// The 'locations' array is set in MainViewController

// http://stackoverflow.com/questions/12504294/programmatically-open-maps-app-in-ios-6


@end
