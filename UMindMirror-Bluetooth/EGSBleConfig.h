//
//  EGSBleConfig.h
//  UMindMirrorSDK
//
//  Created by YRui on 2023/7/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NotchHzType) {
    NotchHzType60,
    NotchHzType50
};

@interface EGSBleConfig : NSObject

@property(nonatomic, assign)NotchHzType notchHzType;

+ (instancetype)sharedConfig;

@end

NS_ASSUME_NONNULL_END
