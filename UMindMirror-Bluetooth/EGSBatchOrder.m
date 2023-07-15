//
//  EGSBatchOrder.m
//  EGSSDK
//
//  Created by YRui on 2023/4/7.
//  Copyright © 2023 EEGSmart. All rights reserved.
//

#import "EGSBatchOrder.h"
#import "EGSBleConfig.h"

@interface EGSBatchOrder ()

@end


@implementation EGSBatchOrder

- (instancetype)init {
    if (self = [super init]) {
        if ([EGSBleConfig sharedConfig].notchHzType == NotchHzType60) {
            self.NOTCH_60HZ_FILTER = YES;
        } else {
            self.FIR_FILTER = YES;
        }
        self.BATTERY_VAL_DATA = YES;
        self.BODY_TEMP_DATA = YES;

        self.MIC_ALGO = YES;
        self.HR_SPO2_ALGO = YES;
        self.HR_SPO2_DATA = YES;

        self.GYRO_ALGO = YES;
        self.EEG_ALGO = YES;
        self.EEG_DATA = YES;
    }
    return self;
}

- (NSString *)getBatchOrder {
    NSMutableString *strOrder = [NSMutableString new];
    [strOrder appendString:(self.ERR_MSG ? @"0" : @"1")];
    [strOrder appendString:(self.OTHER ? @"0" : @"1")];
    [strOrder appendString:(self.ECG_ALGO ? @"0" : @"1")];
    [strOrder appendString:(self.PRESS_FLOW_DATA ? @"0" : @"1")];
    [strOrder appendString:(self.THER_FLOW_DATA ? @"0" : @"1")];
    [strOrder appendString:(self.NOTCH_60HZ_FILTER ? @"0" : @"1")];
    [strOrder appendString:(self.UPDATE_DEV_NAME ? @"0" : @"1")];
    [strOrder appendString:(self.UPDATE_REPORT ? @"0" : @"1")];
    [strOrder appendString:(self.RECORD_REPORT ? @"0" : @"1")];
    [strOrder appendString:(self.INQUIRE_DEVICE_SN_MSG ? @"0" : @"1")];
    [strOrder appendString:(self.INQUIRE_DEVICE_SW_MSG ? @"0" : @"1")];
    [strOrder appendString:(self.INQUIRE_DEVICE_HW_MSG ? @"0" : @"1")];
    [strOrder appendString:(self.INQUIRE_DEVICE_STATE ? @"0" : @"1")];
    [strOrder appendString:(self.UPDATA_FIRMWARE ? @"0" : @"1")];
    [strOrder appendString:(self.SYS_TIME ? @"0" : @"1")];
    [strOrder appendString:(self.OFFLINE_MODE ? @"0" : @"1")];
    [strOrder appendString:(self.FIR_FILTER ? @"0" : @"1")];
    [strOrder appendString:(self.BATTERY_VAL_DATA ? @"0" : @"1")];
    [strOrder appendString:(self.BODY_TEMP_DATA ? @"0" : @"1")];
    [strOrder appendString:(self.GYRO_TEMP_DATA ? @"0" : @"1")];
    [strOrder appendString:(self.MIC_ALGO ? @"0" : @"1")];
    [strOrder appendString:(self.MIC_DATA ? @"0" : @"1")];
    [strOrder appendString:(self.HR_SPO2_ALGO ? @"0" : @"1")];
    [strOrder appendString:(self.HR_SPO2_DATA ? @"0" : @"1")];
    [strOrder appendString:(self.GYRO_ALGO ? @"0" : @"1")];
    [strOrder appendString:(self.GYRO_DATA ? @"0" : @"1")];
    [strOrder appendString:(self.EEG_ALGO ? @"0" : @"1")];
    [strOrder appendString:(self.EEG_DATA ? @"0" : @"1")];
    [strOrder appendString:(self.MEDITATION_ESENSE ? @"0" : @"1")];
    [strOrder appendString:(self.ATTENTION_ESENSE ? @"0" : @"1")];
    [strOrder appendString:(self.POOR_SIGNAL_QUALITY ? @"0" : @"1")];
    [strOrder appendString:(self.UNKNOWN ? @"0" : @"1")];
    return strOrder;
}

@end
