//
//  AppDelegate.m
//  UMindMirrorSDK
//
//  Created by YRui on 2023/7/14.
//

#import "AppDelegate.h"
#import "EGSShowDataViewController.h"
#import "EGSNavigationController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];

    UINavigationController *nav = [[EGSNavigationController alloc] initWithRootViewController:[EGSShowDataViewController new]];
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    return YES;
}




@end
