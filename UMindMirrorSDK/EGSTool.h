//
//  EGSTool.h
//  UMindMirrorSDK
//
//  Created by YRui on 2023/7/15.
//

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface EGSTool : NSObject

+ (void)rotate360WithDuration:(float)aDuration
                  repeatCount:(float)aRepeatCount
                         view:(UIView *)rotateView;

@end

NS_ASSUME_NONNULL_END
