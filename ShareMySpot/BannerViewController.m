//
//  BannerViewController.m
//  Snap Meet
//
//  Created by chris on 2/24/14.
//  Copyright (c) 2014 Chris Jungmann. All rights reserved.
//

#import "BannerViewController.h"

NSString * const BannerViewActionWillBegin = @"BannerViewActionWillBegin";
NSString * const BannerViewActionDidFinish = @"BannerViewActionDidFinish";


@interface BannerViewController ()

@end

@implementation BannerViewController {
    
    ADBannerView *_bannerView;
    UIViewController *_contentController;
    
}

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (instancetype)initWithContentViewController:(UIViewController *)contentController

{
    
    // If contentController is nil, -loadView is going to throw an exception when it attempts to setup containment of a nil view controller.  Instead, throw the exception here and make it obvious what is wrong.
    
    NSAssert(contentController != nil, @"Attempting to initialize a BannerViewController with a nil contentController.");
    
    self = [super init];
    
    if (self != nil) {
        
        // On iOS 6 ADBannerView introduces a new initializer, use it when available.
        if ([ADBannerView instancesRespondToSelector:@selector(initWithAdType:)]) {
            _bannerView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
            
        } else {
            _bannerView = [[ADBannerView alloc] init];
            
        }
        _contentController = contentController;
        _bannerView.delegate = self;
    }
    
    return self;
    
}

- (void)loadView

{
    UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    [contentView addSubview:_bannerView];
    
    // Setup containment of the _contentController.
    
    [self addChildViewController:_contentController];
    [contentView addSubview:_contentController.view];
    [_contentController didMoveToParentViewController:self];
    
    self.view = contentView;
}


- (void)viewDidLayoutSubviews

{
    // This method will be called whenever we receive a delegate callback from the banner view.
    // (See the comments in -bannerViewDidLoadAd: and -bannerView:didFailToReceiveAdWithError:)
    
    CGRect contentFrame = self.view.bounds, bannerFrame = CGRectZero;
    bannerFrame.size = [_bannerView sizeThatFits:contentFrame.size];
    
    // Check if the banner has an ad loaded and ready for display.  Move the banner off screen if it does not have an ad.
    
    if (_bannerView.bannerLoaded) {
        contentFrame.size.height -= bannerFrame.size.height;
        bannerFrame.origin.y = contentFrame.size.height;
    } else {
        bannerFrame.origin.y = contentFrame.size.height;
    }
    
    _contentController.view.frame = contentFrame;
    _bannerView.frame = bannerFrame;
}



- (void)bannerViewDidLoadAd:(ADBannerView *)banner

{
    
    [UIView animateWithDuration:0.25 animations:^{
        
        // -viewDidLayoutSubviews will handle positioning the banner such that it is either visible or hidden depending upon whether its bannerLoaded property is YES or NO (It will be YES if -bannerViewDidLoadAd: was last called).
        // We just need our view to (re)lay itself out so -viewDidLayoutSubviews will be called.
        // You must not call [self.view layoutSubviews] directly.  However, you can flag the view as requiring layout...
        
        [self.view setNeedsLayout];

        // ...then ask it to lay itself out immediately if it is flagged as requiring layout...
        
        [self.view layoutIfNeeded];
        
        // ...which has the same effect.
    }];
    
}


- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error

{
    // handle error

    
}



- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave

{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BannerViewActionWillBegin object:self];
    
    return YES;
    
}



- (void)bannerViewActionDidFinish:(ADBannerView *)banner

{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BannerViewActionDidFinish object:self];
    
}


@end

// code from: https://developer.apple.com/library/ios/samplecode/iAdSuite/Listings/ContainerBanner_ContainerBanner_BannerViewController_m.html

