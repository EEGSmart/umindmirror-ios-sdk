//
//  EGSSDKManager.h
//  EGSSDK
//
//  Created by mopellet on 16/1/11.
//  Copyright © 2016年 EEGSmart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EGSBLEManager.h"
#import "EGSBatchOrder.h"
#import "EGSAnalysisProtocol.h"


/**
 *  本SDK的管理类。蓝牙连接、数据分析结果通过此类管理获取。
 */
@interface EGSSDKManager : NSObject

/** 蓝牙4.0管理类 */
@property (nonatomic, readonly, strong) EGSBLEManager *bleManager;
/** 是否连接设备 */
@property (nonatomic, readonly, assign) BOOL isConnectedDevice;
/** 蓝牙连接的代理 */
@property (nonatomic, readwrite, weak) id<EGSBLEManagerDelegate> bleDelegate;
/** 数据分析的代理 */
@property (nonatomic, readwrite, weak) id<EGSAnalysisProtocol> analysisDelegate;


/// EGSSDKManager singleton
+ (EGSSDKManager *)sharedManager;


/// 发送数据
/// @param data <#data description#>
/// @param identifier peripheral.identifier.UUIDString
- (void)sendByteToBLE:(NSData *)data forIdentifier:(NSString *)identifier;

#pragma mark - 同步报告类

/**
 打开各数据开关
 @param identifier peripheral.identifier.UUIDString
 */
- (void)openControlDatasForIdentifier:(NSString *)identifier;

- (void)openControlDatas:(EGSBatchOrder *)batchOrder forIdentifier:(NSString *)identifier;

/// 设置陷波器
/// - Parameters:
///   - isOn: 是否打开
///   - type: 1:50Hz , 2:60Hz
///   - identifier: <#identifier description#>
- (void)openHertzTrap:(BOOL)isOn type:(NSInteger)type forIdentifier:(NSString *)identifier;

/// 关机
/// @param identifier <#identifier description#>
- (void)sendShutDownForIdentifier:(NSString *)identifier;

@end
