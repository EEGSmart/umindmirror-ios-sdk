//
//  EGSmartDataParser.h
//  EEGSmartSDK
//
//  Created by 成传友 on 16/5/10.
//  Copyright © 2016年 EEGSmart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EGSAnalysisProtocol.h"

typedef NS_ENUM(NSUInteger, ControlType){
    
    /// 信号质量
    CONTROL_TYPE_POOR_SIGNAL_QUALITY     = 0x01,
    ///脑电数据
    CONTROL_TYPE_EEG_DATA                = 0x04,
    /// 脑电算法
    CONTROL_TYPE_EEG_ALGO                = 0x05,
    /// 陀螺仪数据
    CONTROL_TYPE_GYRO_DATA               = 0x06,
    /// 陀螺仪算法
    CONTROL_TYPE_GYRO_ALGO               = 0x07,
    ///50Hz陷波
    CONTROL_TYPE_FIR_FILTER              = 0x0f,
    /// 时间同步
    CONTROL_TYPE_UPDATE_TIME             = 0x11,
    /// 固件升级
    CONTROL_TYPE_UPDATA_FIRMWARE         = 0x12,
    ///查询设备硬件版本
    CONTROL_TYPE_INQUIRE_DEVICE_HARDWARE = 0x14,
    ///查询设备软件版本
    CONTROL_TYPE_INQUIRE_DEVICE_SOFTWARE = 0x15,
    ///查询设备SN
    CONTROL_TYPE_INQUIRE_DEVICE_SN       = 0x16,
    ///60hz陷波
    CONTROL_TYPE_NOTCH_60HZ_FILTER       = 0x1a,
    ///组合控制开关
    CONTROL_TYPE_BATCH_CONTROL           = 0x20,
    ///关机信息
    CONTROL_TYPE_POWER_OFF               = 0x21,
    ///包序号
    CONTROL_TYPE_PACKET_NUM              = 0xF1,
    ///HST设备电量
    CONTROL_TYPE_BATTERY_SUP_DATA        = 0x3A,

};

typedef NS_ENUM(NSUInteger, SWITCH_TYPE){
    SWITCH_TYPE_OPEN,
    SWITCH_TYPE_CLOSE
};


extern NSString const * kSwithControlType;
extern NSString const * kSwithControlValue;

@interface EGSmartDataParser : NSObject 
@property (weak, nonatomic) id<EGSAnalysisProtocol> delegate;

/**
 *  解析数据
 *
 *  @param data 需要解析的蓝牙数据
 */
- (void)parseData:(NSData *)data forIdentifier:(NSString *)identifier;

/// 清空缓存数据，如果传控，清除所有
/// @param identifier peripheral.identifier.UUIDString
- (void)removeBufferForIdentifier:(nullable NSString *)identifier;


@end
