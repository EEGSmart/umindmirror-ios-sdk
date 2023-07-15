//
//  UIView+Helpers.m
//  LYKJShopping
//
//  Created by hx on 2018/5/11.
//  Copyright © 2018年 LD. All rights reserved.
//

#import "UIView+Helpers.h"

@implementation UIView (Helpers)

- (CGSize)size {
    return self.frame.size;
}

- (void)setSize:(CGSize)size {
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

- (CGFloat)x {
    return self.frame.origin.x;
}

- (void)setX:(CGFloat)x {
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (CGFloat)y {
    return self.frame.origin.y;
}

- (void)setY:(CGFloat)y {
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (CGFloat)width {
    return self.frame.size.width;
}

- (void)setWidth:(CGFloat)width {
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (CGFloat)height {
    return self.frame.size.height;
}

- (void)setHeight:(CGFloat)height {
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (CGFloat)centerX {
    return self.center.x;
}

- (void)setCenterX:(CGFloat)centerX {
    CGPoint center = self.center;
    center.x = centerX;
    self.center = center;
}

- (CGFloat)centerY {
    return self.center.y;
}

- (void)setCenterY:(CGFloat)centerY {
    CGPoint center = self.center;
    center.y = centerY;
    self.center = center;
}

- (CGFloat)maxX {
    return CGRectGetMaxX(self.frame);
}

- (void)setMaxX:(CGFloat)maxX {
    self.x = maxX - self.width;
}

- (CGFloat)maxY {
    return CGRectGetMaxY(self.frame);
}

- (void)setMaxY:(CGFloat)maxY {
    self.y = maxY - self.height;
}

static inline CGRect CGRectRound(CGRect rect) {return CGRectMake((CGFloat)rect.origin.x, (CGFloat)rect.origin.y, (CGFloat)rect.size.width, (CGFloat)rect.size.height); }


#pragma mark - Debugging

- (void)showDebugFrame
{
    [self showDebugFrame:NO];
}

- (void)hideDebugFrame
{
    [[self layer] setBorderColor:nil];
    [[self layer] setBorderWidth:0.0f];
}

- (void)showDebugFrame:(BOOL)showInRelease
{
    [self performInRelease:showInRelease
                     block:^{
                         [[self layer] setBorderColor:[[UIColor redColor] CGColor]];
                         [[self layer] setBorderWidth:1.0f];
                     }];
    
}

- (void)performInRelease:(BOOL)release block:(void (^)(void))block
{
    if (block)
    {
#ifdef DEBUG
        block();
#else
        if (release)
        {
            block();
        }
#endif
    }
}

- (void)isCornerRadius
{
    self.layer.cornerRadius = MAX(self.width,self.height)/2;
    self.layer.masksToBounds = YES;
    
}


- (UIViewController *)responsViewController {
    UIView *view = self;
    while ((view = [view superview])) {
        if ([[view nextResponder] isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)[view nextResponder];
        }
    }
    return nil;
}



#pragma mark -
#pragma mark Alignment

- (void)centerAlignHorizontalForView:(UIView *)view
{
    [self centerAlignHorizontalForView:view offset:0];
}

- (void)centerAlignVerticalForView:(UIView *)view
{
    [self centerAlignVerticalForView:view offset:0];
}

- (void)centerAlignHorizontalForSuperView
{
    [self centerAlignHorizontalForView:[self superview]];
}

- (void)centerAlignVerticalForSuperView
{
    [self centerAlignVerticalForView:[self superview]];
}

- (void)centerAlignHorizontalForSuperView:(CGFloat)offset
{
    [self centerAlignHorizontalForView:[self superview] offset:offset];
}

- (void)centerAlignVerticalForSuperView:(CGFloat)offset
{
    [self centerAlignVerticalForView:[self superview] offset:offset];
}

- (void)centerAlignForView:(UIView *)view
{
    [self centerAlignHorizontalForView:view];
    [self centerAlignVerticalForView:view];
}

- (void)centerAlignForSuperview
{
    [self centerAlignForView:[self superview]];
}

- (void)centerAlignHorizontalForView:(UIView *)view offset:(CGFloat)offset
{
    [self setFrame:CGRectRound(CGRectMake((CGRectGetWidth([view frame]) / 2.0f) - (CGRectGetWidth([self frame]) / 2.0f) + offset, CGRectGetMinY([self frame]), CGRectGetWidth([self frame]), CGRectGetHeight([self frame])))];
}

- (void)centerAlignVerticalForView:(UIView *)view offset:(CGFloat)offset
{
    [self setFrame:CGRectRound(CGRectMake(CGRectGetMinX([self frame]), (CGRectGetHeight([view frame]) / 2.0f) - (CGRectGetHeight([self frame]) / 2.0f) + offset, CGRectGetWidth([self frame]), CGRectGetHeight([self frame])))];
}

@end
