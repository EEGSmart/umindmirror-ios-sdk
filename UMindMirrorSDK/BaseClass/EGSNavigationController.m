//
//  EGSNavigationController.m
//  UMindMirrorSDK
//
//  Created by YRui on 2023/7/15.
//

#import "EGSNavigationController.h"

@interface EGSNavigationController ()

@end

@implementation EGSNavigationController


- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.viewControllers.count > 0) {
        viewController.hidesBottomBarWhenPushed = YES;
    }
    
    [super pushViewController:viewController animated:animated];
}


- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.topViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.topViewController;
}


@end
