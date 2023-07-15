//
//  EGSBatchOrder.h
//  EGSSDK
//
//  Created by YRui on 2023/4/7.
//  Copyright © 2023 EEGSmart. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 批处理命令
@interface EGSBatchOrder : NSObject

@property(nonatomic, assign) BOOL ERR_MSG;
@property(nonatomic, assign) BOOL OTHER;

/// 开关心电算法
@property(nonatomic, assign) BOOL ECG_ALGO;

/// 开关压力气流数据
@property(nonatomic, assign) BOOL PRESS_FLOW_DATA;

/// 开关热敏气流数据
@property(nonatomic, assign) BOOL THER_FLOW_DATA;

/// 设置60Hz陷波器
@property(nonatomic, assign) BOOL NOTCH_60HZ_FILTER;
@property(nonatomic, assign) BOOL UPDATE_DEV_NAME;
@property(nonatomic, assign) BOOL UPDATE_REPORT;


@property(nonatomic, assign) BOOL RECORD_REPORT;
@property(nonatomic, assign) BOOL INQUIRE_DEVICE_SN_MSG;
@property(nonatomic, assign) BOOL INQUIRE_DEVICE_SW_MSG;
@property(nonatomic, assign) BOOL INQUIRE_DEVICE_HW_MSG;


@property(nonatomic, assign) BOOL INQUIRE_DEVICE_STATE;
@property(nonatomic, assign) BOOL UPDATA_FIRMWARE;
@property(nonatomic, assign) BOOL SYS_TIME;
@property(nonatomic, assign) BOOL OFFLINE_MODE;


/// 设置50Hz陷波器
@property(nonatomic, assign) BOOL FIR_FILTER;

/// 开关电池电压数据
@property(nonatomic, assign) BOOL BATTERY_VAL_DATA;

/// 开关人体温度数据
@property(nonatomic, assign) BOOL BODY_TEMP_DATA;
@property(nonatomic, assign) BOOL GYRO_TEMP_DATA;


/// 开关鼾声算法
@property(nonatomic, assign) BOOL MIC_ALGO;

/// 开关麦克风数据
@property(nonatomic, assign) BOOL MIC_DATA;

/// 开关心率血氧算法
@property(nonatomic, assign) BOOL HR_SPO2_ALGO;

/// 开关心率血氧PPG数据。
@property(nonatomic, assign) BOOL HR_SPO2_DATA;


/// 开关陀螺仪算法
@property(nonatomic, assign) BOOL GYRO_ALGO;

/// 开关陀螺仪数据
@property(nonatomic, assign) BOOL GYRO_DATA;

/// 开关脑电算法
@property(nonatomic, assign) BOOL EEG_ALGO;

/// 开关脑电数据
@property(nonatomic, assign) BOOL EEG_DATA;


@property(nonatomic, assign) BOOL MEDITATION_ESENSE;
@property(nonatomic, assign) BOOL ATTENTION_ESENSE;
@property(nonatomic, assign) BOOL POOR_SIGNAL_QUALITY;
@property(nonatomic, assign) BOOL UNKNOWN;



- (NSString *)getBatchOrder;

@end

NS_ASSUME_NONNULL_END
