//
//  DetailViewController.h
//  Snap Meet
//
//  Created by chris on 3/12/14.
//  Copyright (c) 2014 Chris Jungmann. All rights reserved.
//

@class DetailViewController;

// delegate implemented in LocationsViewController
@protocol DetailViewControllerDelegate <NSObject>

- (void)detailViewRowDelete:(DetailViewController *)dvc deleteItem:(NSInteger)item;

@end


#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <MapKit/MapKit.h>

#import "AppDelegate.h"

#define SharedAdBannerView ((AppDelegate *)[[UIApplication sharedApplication] delegate]).adBanner


@interface DetailViewController : UIViewController <MKMapViewDelegate, ADBannerViewDelegate>

// detail view delegate
@property (weak, nonatomic) id<DetailViewControllerDelegate> delegate;

// holds details of selected location
@property (nonatomic, strong) PFObject *selectedLocation;

// display properties
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@property (weak, nonatomic) IBOutlet UIImageView *mapView;
@property (weak, nonatomic) IBOutlet UIImageView *snapView;

// this property is set from LocationsVC in prepareForSegue
@property (assign, nonatomic) NSInteger locationRow;

@property (weak, nonatomic) IBOutlet UIButton *navigateButtonOutlet;
@property (weak, nonatomic) IBOutlet UIButton *deleteButtonOutlet;


// button properties
// user requests directions
- (IBAction)navitageButton:(id)sender;
// user wishes to delete this record
- (IBAction)deleteButton:(id)sender;

@end
