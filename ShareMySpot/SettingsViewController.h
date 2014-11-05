//
//  SettingsViewController.h
//  Snap Meet
//
//  Created by chris on 6/25/14.
//  Copyright (c) 2014 Chris Jungmann. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AddressBookUI/AddressBookUI.h>
#import "MapViewController.h"


@interface SettingsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *statusGPSLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusABookLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusFaceBookLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusCameraLabel;

@property (strong, nonatomic) NSString *currentUserURL;


@end
