//
//  EGSBleConfig.m
//  UMindMirrorSDK
//
//  Created by YRui on 2023/7/15.
//

#import "EGSBleConfig.h"

@interface EGSBleConfig()<NSCopying, NSMutableCopying>

@end

static EGSBleConfig *singleton = nil;

@implementation EGSBleConfig

+ (instancetype)sharedConfig {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[[self class] alloc] init];
        singleton.notchHzType = NotchHzType60;
    });
    return singleton;
}

///用alloc返回也是唯一实例
+ (id)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [super allocWithZone:zone];
    });
    return singleton;
}

///对对象使用copy也是返回唯一实例
- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return singleton;
}

 ///对对象使用mutablecopy也是返回唯一实例
- (nonnull id)mutableCopyWithZone:(nullable NSZone *)zone {
    return singleton;
}


@end

