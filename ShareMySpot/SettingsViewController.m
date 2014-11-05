//
//  SettingsViewController.m
//  Snap Meet
//
//  Created by chris on 6/25/14.
//  Copyright (c) 2014 Chris Jungmann. All rights reserved.
//

#import "SettingsViewController.h"

@implementation SettingsViewController

- (void)viewDidLoad {
    
    // TODO: Localize text here
    
    // check access GPS is allowed
    if ([CLLocationManager locationServicesEnabled]) {
        self.statusGPSLabel.text = @"Allowed";
    } else {
        self.statusGPSLabel.text = @"Disabled";
    }
    
    // check address book access is allowed:
    if ([ABPeoplePickerNavigationController accessInstanceVariablesDirectly]) {
        self.statusABookLabel.text = @"Allowed";
    } else {
        self.statusABookLabel.text = @"Disabled";
    }
    
    // check for camera
    if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront] || [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
        
        self.statusCameraLabel.text = @"Ok";
    } else {
        self.statusCameraLabel.text = @"None";
    }
    
    if (self.currentUserURL) {
        self.statusFaceBookLabel.text = @"Allowed";
    } else {
        self.statusFaceBookLabel.text = @"None";
    }
    
}

@end

