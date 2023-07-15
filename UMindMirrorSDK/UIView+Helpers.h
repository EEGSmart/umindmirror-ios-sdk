//
//  UIView+Helpers.h
//  LYKJShopping
//
//  Created by hx on 2018/5/11.
//  Copyright © 2018年 LD. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Helpers)

- (void)showDebugFrame;
- (void)hideDebugFrame;
- (void)showDebugFrame:(BOOL)showInRelease;
- (void)isCornerRadius;

- (UIViewController *)responsViewController;


@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGFloat centerX;
@property (nonatomic, assign) CGFloat centerY;
@property (nonatomic, assign) CGFloat maxX;
@property (nonatomic, assign) CGFloat maxY;

- (void)centerAlignHorizontalForView:(UIView *)view;
- (void)centerAlignVerticalForView:(UIView *)view;

- (void)centerAlignHorizontalForView:(UIView *)view offset:(CGFloat)offset;
- (void)centerAlignVerticalForView:(UIView *)view offset:(CGFloat)offset;
- (void)centerAlignForView:(UIView *)view;

- (void)centerAlignForSuperview;
- (void)centerAlignHorizontalForSuperView;
- (void)centerAlignVerticalForSuperView;
@end
