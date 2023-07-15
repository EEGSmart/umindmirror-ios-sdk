//
//  EGSSDKHelper.h
//  EGSSDK
//
//  Created by mopellet on 17/4/7.
//  Copyright © 2017年 EEGSmart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "EGSBLEManagerDelegate.h"
#import "EGSBatchOrder.h"
#import "EGSAnalysisProtocol.h"


#define SDKHelper [EGSSDKHelper sharedHelper]

@protocol EGSSDKHelperProtocol <EGSAnalysisProtocol, EGSBLEManagerDelegate>

@end

@interface EGSSDKHelper : NSObject

+ (instancetype)sharedHelper;

/** 是否连接了设备*/
@property (nonatomic ,assign, readonly) BOOL isConnectDevice;

/// 连接中的umind设备 未连接nil
@property (strong, nonatomic, readonly) CBPeripheral *umindPeripheral;


/// 已连接的设备
@property (strong, nonatomic, readonly) NSArray<CBPeripheral *> *connectedPeripherals;

/** 蓝牙状态*/
@property (assign,nonatomic, readonly) CBManagerState state;



@property (assign, nonatomic, readonly) NSInteger battery;
@property (strong, nonatomic, readonly) NSString *hardWare;
@property (strong, nonatomic, readonly) NSString *softWare;
@property (strong, nonatomic, readonly) NSString *snCode;

///最新连接的umind设备的identifier 用于自动连接
@property (strong, nonatomic, readonly) NSString *lastConnectedDeviceIdentifier;


/// 注册监听
/// @param delegate <#delegate description#>
- (void)addServerDelegate:(id<EGSSDKHelperProtocol>)delegate;

/// 移除监听
/// @param delegate <#delegate description#>
- (void)removeServerDelegate:(id<EGSSDKHelperProtocol>)delegate;

- (void)removeAllServerDelegate;


/// 查找蓝牙设备
/// @param isAutoConnect <#isAutoConnect description#>
- (void)startDiscoveringDevices:(BOOL)isAutoConnect;


// 停止扫描设备
- (void)stopScan;

/// 连接蓝牙设备
/// @param peripheral 蓝牙设备
- (void)connectPeripheral:(CBPeripheral *)peripheral;

/// 断开蓝牙设备
/// @param peripheral peripheral nil 为断开所有
- (void)disConnectPeripheral:(CBPeripheral *)peripheral;



/**
 打开各数据开关
 本意是不暴露给外界的，现UI需要控制so暴露给外界方法 2018-08
 */
- (void)openControlDatasForIdentifier:(NSString *)identifier;

- (void)openControlDatas:(EGSBatchOrder *)batchOrder forIdentifier:(NSString *)identifier;

/// 设置陷波器
/// - Parameters:
///   - isOn: 是否打开
///   - type: 1:50Hz , 2:60Hz
///   - identifier: <#identifier description#>
- (void)openHertzTrap:(BOOL)isOn type:(NSInteger)type forIdentifier:(NSString *)identifier;


- (void)removeLastPairedDeviceIdentifier;


/// 判断是否SMMY设备
/// @param peripheral 蓝牙从属设备
+ (BOOL)isSMMYPeripheral:(CBPeripheral *)peripheral;


/// 睡眠仪是否是C1型号
/// @param snCode 序列号
+ (BOOL)isSleeperModelC1:(NSString *)snCode;

/// 睡眠仪是否是S1型号
/// @param snCode 序列号
+ (BOOL)isSleeperModelS1:(NSString *)snCode;

/// 睡眠仪是否是E1型号
/// @param snCode 序列号
+ (BOOL)isSleeperModelE1:(NSString *)snCode;


/// 获取连接中的设备
/// @param identifier <#identifier description#>
+ (CBPeripheral *)connectedPeripheralWithIdentifier:(NSString *)identifier;

@end
