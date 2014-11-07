//
//  BannerViewController.h
//  Snap Meet
//
//  Created by chris on 2/24/14.
//  Copyright (c) 2014 Chris Jungmann. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>

extern NSString * const BannerViewActionWillBegin;
extern NSString * const BannerViewActionDidFinish;

@interface BannerViewController : UIViewController <ADBannerViewDelegate>

- (instancetype)initWithContentViewController:(UIViewController *)contentController;

@end
