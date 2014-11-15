//
//  AppDelegate.m
//  Snap Meet
//
//  Created by chris on 1/13/14.
//  Copyright (c) 2014 Chris Jungmann. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize locationsCount;
@synthesize adBanner;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    NSLog(@"[application]: didFinishLaunchingWithOptions");

    [Parse setApplicationId:@"Kpj3EaiTKvG9DTnQcxr3HvifFS5tX4ShOW3Mw5z6"
                  clientKey:@"AYnqQ0Kxz69wTSb2KloXNuvtn1jIK9fh26qPZeOT"];
    
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];

    // Register for push notifications. (Deprecated)
//    [application registerForRemoteNotificationTypes: UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound];
    
    // updated resistration for push notifications
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge
                                                                                             |UIUserNotificationTypeSound
                                                                                             |UIUserNotificationTypeAlert) categories:nil];
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
        
    } else {
        
        // this code is used for version prior to iOS 8.0
        [application registerForRemoteNotificationTypes: UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound];

    }
    
    
    // implement Parse/Facebook integrated login 2-28-14
    [PFFacebookUtils initializeFacebook];
    
    // set nav bar background colour
    [self customizeUserInterface];
    
    // implement global iAd process.  added 2-24-14
    adBanner = [[ADBannerView alloc] init];
    adBanner.delegate = self;
    
    return YES;
}

// App switching method to support Facebook Single Sign-On.
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *) sourceApplication annotation:(id)annotation {
    
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication withSession:[PFFacebookUtils session]];
}

// succesful completion of the registration process
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    NSLog(@"[application]: didRegisterForRemoteNotificationsWithDeviceToken");

    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:newDeviceToken];
    
    // add method to reset the badge added 3-14-14
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
    }
    
    [currentInstallation saveInBackground];
}

// unsuccesful completion of the regitration process
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    
    NSLog(@"[application]: didFailToRegisterForRemoteNotificationsWithError: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    // notification is received while the app is active, ask Parse to handle it for us.
    NSLog(@"[application]: didReceiveRemoteNotification");
    
    [PFPush handlePush:userInfo];
    
    // Reload the MainViewContoller if app is active.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"remoteNotification" object:nil];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state.
    NSLog(@"[application]: applicationWillResignActive");
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers.
    NSLog(@"[application]: applicationDidEnterBackground");

}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state.
    NSLog(@"[application]: applicationWillEnterForeground");

    // Set up notification to reset the badge count if app becomes active from the background.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"enterForeground" object:nil];
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive.
    NSLog(@"[application]: applicationDidBecomeActive");
    
    // Integrated login Parse with FB
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
    
    

}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate.
    NSLog(@"[application]: applicationWillTerminate");
    
    [[PFFacebookUtils session] close];

}

- (void)customizeUserInterface {
    
    // set nav bar backgound
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:0.8 green:0.9 blue:1.0 alpha:1.0]];
    
    // set nav bar title color
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, nil]];
    
    // set nav bar other text labels and buttons color
    [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:0.25f green:0.45f blue:0.90f alpha:1]];
    
}

@end

// creaned up code.  Removed MainVC import from .m and moved parse.h import to h. 3-8-14
// removed 'if (application.applicationState == UIApplicationStateActive) {' in d-dRecieveRemoteNotification

