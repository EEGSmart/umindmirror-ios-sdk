//
//  EGSBaseViewController.m
//  UMindMirrorSDK
//
//  Created by YRui on 2023/7/15.
//

#import "EGSBaseViewController.h"

@interface EGSBaseViewController ()<UIGestureRecognizerDelegate>

@end

@implementation EGSBaseViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.defaultBackBtn = YES;
}

- (void)setDefaultBackBtn:(BOOL)defaultBackBtn {
    _defaultBackBtn = defaultBackBtn;
    if (defaultBackBtn) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"back"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(backAction)];
        self.navigationItem.leftBarButtonItem.imageInsets = UIEdgeInsetsMake(0, -9, 0, 0);
    }
}

- (void)backAction {
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark StatusBarStyle
- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return self.statusBarAnimation;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.statusBarStyle;
}

- (BOOL)prefersStatusBarHidden {
    return self.hiddenStatusbar;
}
@end
