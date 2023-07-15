//
//  EGSBLEManager.h
//  EGSSDK
//
//  Created by mopellet on 15/12/23.
//  Copyright © 2015年 EEGSmart. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <ExternalAccessory/ExternalAccessory.h>
#import "EGSBLEManagerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/*! 蓝牙4.0管理类 */
@interface EGSBLEManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (weak, nonatomic) id<EGSBLEManagerDelegate> delegate;

/*! 蓝牙扫描、连接类（不要设置此类的delegate，否EGSBLEManager其它方法将失效）*/
@property (strong, readonly, nonatomic) CBCentralManager *centraManager;
/*! 扫描到的从属蓝牙设备 */
@property (strong, readonly, nonatomic) NSMutableArray<CBPeripheral *> *peripherals;
/*! 已连接的从属蓝牙设备（不要设置此类的delegate，否EGSBLEManager其它方法将失效）*/
@property (strong, readonly, nonatomic, nullable) NSMutableArray<CBPeripheral *> *connectedPeripherals;
/*! 是否正在连接从属蓝牙设备 */
@property (assign, readonly, nonatomic) BOOL connecting;
/*! 连接中的从属蓝牙设备 */
@property (weak, readonly, nonatomic, nullable) CBPeripheral *connectingPeripheral;


/// 通过peripheral.identifier.UUIDString 返回连接的设备
/// @param identifier <#identifier description#>
- (nullable CBPeripheral *)connectedPeripheralWithIdentifier:(NSString *)identifier;

/**
 *  扫描从属蓝牙设备
 *
 *  @param serviceUUIDs 指定扫描包含特定服务的从属蓝牙设备（传nil扫描所有蓝牙4.0设备）
 *  @param timeout      扫描超时时间（超时后停止扫描）
 *
 *  @return 如果手机蓝牙未打开返回NO，其它情况YES
 */
- (BOOL)scanPeripheralsWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs
                            timeout:(NSTimeInterval)timeout;

/**
 *  扫描从属蓝牙设备
 *
 *  @param serviceUUIDs 指定扫描包含特定服务的从属蓝牙设备（传nil扫描所有蓝牙4.0设备）
 *
 *  @return 如果手机蓝牙未打开返回NO，其它情况YES
 */
- (BOOL)scanPeripheralsWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs;


/**
 *  停止扫描从属蓝牙设备
 */
- (void)stopScan;

/**
 *  连接从属蓝牙设备
 *
 *  @param peripheral 要连接的从属蓝牙设备
 */
- (void)connectPeripheral:(CBPeripheral *)peripheral;

/**
 *  断开从属蓝牙设备的连接
 *
 *  @param peripheral 要断开的从属蓝牙设备。传nil的时候断开连接中的从属蓝牙设备
 */
- (void)cancelPeripheralConnection:(nullable CBPeripheral *)peripheral;

/**
 *  开启/关闭监听从属蓝牙设备某个服务的特征
 *
 *  @param p     从属蓝牙设备
 *  @param on    是否监听
 *  @param sUUID 服务的UUID
 *  @param cUUID 特征的UUID
 */
- (void)notifyPeripheral:(CBPeripheral *)p on:(BOOL)on forService:(CBUUID *)sUUID characteristicUUID:(CBUUID *)cUUID;

/**
 *  读取从属蓝牙设备某个服务的特征
 *
 *  @param p     从属蓝牙设备
 *  @param sUUID 服务的UUID
 *  @param cUUID 特征的UUID
 */
- (void)readPeripheral:(CBPeripheral *)p valueForService:(CBUUID *)sUUID characteristicUUID:(CBUUID *)cUUID;

/**
 *  向从属蓝牙设备发送数据 WriteWithoutResponse
 *
 *  @param p     从属蓝牙设备
 *  @param sUUID 服务的UUID
 *  @param cUUID 特征的UUID
 *  @param data  要发送的数据
 */
- (void)writePeripheral:(CBPeripheral *)p forService:(CBUUID *)sUUID characteristicUUID:(CBUUID *)cUUID withData:(NSData *)data;

/**
 *  向从属蓝牙设备发送数据 WithResponse
 *
 *  @param p     从属蓝牙设备
 *  @param sUUID 服务的UUID
 *  @param cUUID 特征的UUID
 *  @param data  要发送的数据
 */
- (void)writePeripheralWithResponse:(CBPeripheral *)p forService:(CBUUID *)sUUID characteristicUUID:(CBUUID *)cUUID withData:(NSData *)data;

#pragma mark - EEGSmart

/**
 *  EEGSmart所具有的服务CBUUID
 *
 *  @return EEGSmart所具有的服务CBUUID
 */
+ (CBUUID *)EEGSmartServiceUUID;


/**
 *  EEGSmart数据广播的特征CBUUID
 *
 *  @return EEGSmart数据广播的特征CBUUID
 */
+ (CBUUID *)EEGSmartCharacteristicNotifyUUID;

/**
 *  支持的所有的蓝牙服务CBUUIDs
 *
 *  @return 支持的所有的蓝牙服务CBUUIDs
 */
+ (NSArray<CBUUID *> *)allSupportedServiceUUIDs;

/**
 *  支持的所有的读特征CBUUIDs
 *
 *  @return 支持的所有的特征CBUUIDs
 */
+ (NSArray<CBUUID *> *)allSupportedCharacteristicNotifyUUIDs;

/**
 *  支持的所有的读特征CBUUID Strings
 *
 *  @return 支持的所有的读特征CBUUID Strings
 */
+ (NSArray<NSString *> *)allSupportedCharacteristicNotifyUUIDStrings;

/**
 *  支持的所有的写特征CBUUIDs
 *
 *  @return 支持的所有的特征CBUUIDs
 */
+ (NSArray<CBUUID *> *)allSupportedCharacteristicWirteUUIDs;


/**
 *  扫描从属蓝牙设备的所有特征
 *
 *  @param p 从属蓝牙设备
 */
- (void)discoverAllCharacteristicsForPeripheral:(CBPeripheral *)p;

@end

NS_ASSUME_NONNULL_END
