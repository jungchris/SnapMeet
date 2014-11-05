//
//  LocationsViewController.h
//  ShareMySpot
//
//  Created by chris on 1/17/14.
//  Copyright (c) 2014 Chris Jungmann. All rights reserved.
//

@class LocationsViewController;

// delegate implemented in LocationsViewController
@protocol LocationsViewControllerDelegate <NSObject>

- (void)locationViewRowDelete:(LocationsViewController *)lvc deleteItem:(NSInteger)item;

@end

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import <Parse/Parse.h>
#import "MainViewController.h"
#import "DetailViewController.h"


@interface LocationsViewController : UITableViewController <MKMapViewDelegate, DetailViewControllerDelegate>

// detail view delegate
@property (weak, nonatomic) id<LocationsViewControllerDelegate> delegate;


@property (nonatomic, strong) PFUser *currentUser;

// holds location objects returned by findObjectsInBackgroundWith Block
@property (nonatomic, strong) NSArray *locations;

// holds property of selected location
@property (nonatomic, strong) PFObject *selectedLocation;

// used to set the row in DetailViewController
@property (assign, nonatomic) NSInteger locationRow;

@end
