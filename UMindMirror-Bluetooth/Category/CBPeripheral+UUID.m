//
//  CBPeripheral+UUID.m
//  EGSSDK
//
//  Created by YRui on 2022/3/3.
//  Copyright © 2022 EEGSmart. All rights reserved.
//

#import "CBPeripheral+UUID.h"

#import <objc/runtime.h>

@implementation CBPeripheral (UUID)

- (void)setWriteServiceUUID:(CBUUID *)writeServiceUUID {
    objc_setAssociatedObject(self, @selector(writeServiceUUID), writeServiceUUID, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CBUUID *)writeServiceUUID {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setWriteCharacteristicUUID:(CBUUID *)writeCharacteristicUUID {
    objc_setAssociatedObject(self, @selector(writeCharacteristicUUID), writeCharacteristicUUID, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CBUUID *)writeCharacteristicUUID {
    return objc_getAssociatedObject(self, _cmd);
}

@end
