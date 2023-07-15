//
//  EGSBaseViewController.h
//  UMindMirrorSDK
//
//  Created by YRui on 2023/7/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface EGSBaseViewController : UIViewController

@property (nonatomic, assign) BOOL defaultBackBtn;
// 是否隐藏状态栏
@property (nonatomic, assign) BOOL hiddenStatusbar;
// 状态栏样式
@property (nonatomic, assign) UIStatusBarStyle statusBarStyle;
// 状态栏动画
@property (nonatomic, assign) UIStatusBarAnimation statusBarAnimation;

@end

NS_ASSUME_NONNULL_END
