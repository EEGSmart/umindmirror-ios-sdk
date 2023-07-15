//
//  CBPeripheral+Property.m
//  UMSSleepRecorder
//
//  Created by 云睿 on 2021/3/4.
//

#import "CBPeripheral+Property.h"

#import <objc/runtime.h>

static char *kRssiValKey = "RssiValKey";
static char *kBatValKey = "BatValKey";
static char *kIsChargeValKey = "isChargeKey";
static char *kSnCodeKey = "snCodeKey";


@implementation CBPeripheral (Property)

- (void)setRssiVal:(NSNumber *)rssiVal {
    objc_setAssociatedObject(self, kRssiValKey, rssiVal, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)rssiVal {
    return objc_getAssociatedObject(self, kRssiValKey);
}

- (void)setBatVal:(NSNumber *)batVal {
    objc_setAssociatedObject(self, kBatValKey, batVal, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)batVal {
    return objc_getAssociatedObject(self, kBatValKey);
}

//- (void)setIsCharge:(BOOL)isCharge {
//    objc_setAssociatedObject(self, @selector(isCharge), @(isCharge), OBJC_ASSOCIATION_ASSIGN);
//}
//
//- (BOOL)isCharge {
//    return [objc_getAssociatedObject(self, _cmd) boolValue];
//}

- (void)setChargeState:(NSInteger)chargeState {
    objc_setAssociatedObject(self, @selector(chargeState), @(chargeState), OBJC_ASSOCIATION_ASSIGN);
}

- (NSInteger)chargeState {
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

- (void)setSnCode:(NSString *)snCode {
    objc_setAssociatedObject(self, kSnCodeKey, snCode, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)snCode {
    return objc_getAssociatedObject(self, kSnCodeKey);
}

@end
