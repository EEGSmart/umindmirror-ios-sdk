//
//  CBPeripheral+Property.h
//  UMSSleepRecorder
//
//  Created by 云睿 on 2021/3/4.
//

#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN


@interface CBPeripheral (Property)

@property (nonatomic, strong) NSNumber *rssiVal;

@property (nonatomic, strong) NSNumber *batVal;

/// 充电状态   0：未充电  1：充电中  2：充电完成
@property (nonatomic, assign) NSInteger chargeState;

@property (nonatomic, copy) NSString *snCode;

@end

NS_ASSUME_NONNULL_END
