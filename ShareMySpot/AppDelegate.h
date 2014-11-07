//
//  AppDelegate.h
//  Snap Meey
//
//  Created by chris on 1/13/14.
//  Copyright (c) 2014 Chris Jungmann. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <iAd/iAd.h>
#import <FacebookSDK/FacebookSDK.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, ADBannerViewDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (assign, nonatomic) NSInteger locationsCount;

@property (nonatomic, strong) ADBannerView *adBanner;

@end
