//
//  EGSTool.m
//  UMindMirrorSDK
//
//  Created by YRui on 2023/7/15.
//

#import "EGSTool.h"



@implementation EGSTool

+ (void)rotate360WithDuration:(float)aDuration
                  repeatCount:(float)aRepeatCount
                         view:(UIView *)rotateView {
    CAKeyframeAnimation *theAnimation = [CAKeyframeAnimation animation];
    theAnimation.values = [NSArray arrayWithObjects:
                           [NSValue valueWithCATransform3D:CATransform3DMakeRotation(0, 0,0,1)],
                           [NSValue valueWithCATransform3D:CATransform3DMakeRotation(3.13, 0,0,1)],
                           [NSValue valueWithCATransform3D:CATransform3DMakeRotation(6.26, 0,0,1)],
                           nil];
    theAnimation.cumulative = YES;
    theAnimation.duration = aDuration;
    theAnimation.repeatCount = aRepeatCount;
    theAnimation.removedOnCompletion = NO;
    theAnimation.fillMode = kCAFillModeForwards;
    [rotateView.layer addAnimation:theAnimation forKey:@"transform"];
}

@end
