//
//  CBPeripheral+UUID.h
//  EGSSDK
//
//  Created by YRui on 2022/3/3.
//  Copyright © 2022 EEGSmart. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

//#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CBPeripheral (UUID)

@property (nonatomic, strong)CBUUID *writeServiceUUID;

@property (nonatomic, strong)CBUUID *writeCharacteristicUUID;

@end

NS_ASSUME_NONNULL_END
