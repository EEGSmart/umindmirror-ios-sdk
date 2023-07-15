//
//  EGSBLEManagerDelegate.h
//  EGSSDK
//
//  Created by mopellet on 17/4/12.
//  Copyright © 2017年 EEGSmart. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol EGSBLEManagerDelegate <NSObject>

@optional
/**
 *  手机蓝牙状态回调代理
 *
 *  @param state 当前手机蓝牙状态
 */
- (void)bleCentralManagerDidUpdateState:(CBManagerState)state;

/**
 *  发现从属蓝牙设备
 *
 *  @param peripheral        从属蓝牙设备
 *  @param advertisementData 从属蓝牙设备广播信息
 *  @param RSSI              从属设备信号大小
 */
- (void)bleDidDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;

/**
 *  已连接从属蓝牙设备(peripheral，只能一个为空)
 *
 *  @param peripheral 从属蓝牙4.0设备
 */
- (void)bleDidConnectPeripheral:(nullable CBPeripheral *)peripheral;

/**
 *  连接从属蓝牙设备失败
 *
 *  @param peripheral 从属蓝牙设备
 *  @param error      失败原因
 */
- (void)bleDidFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error;

/**
 *  从属蓝牙设备断开连接
 *
 *  @param peripheral 从属蓝牙4.0设备
 *  @param error     断开的错误信息（蓝牙主动关闭不会有错误信息）
 */
- (void)bleDidDisconnectPeripheral:(nullable CBPeripheral *)peripheral
                         withError:(nullable NSError *)error;

/**
 *  扫描到从属蓝牙设备的服务
 *
 *  @param peripheral 从属蓝牙设备
 */
- (void)bleDidDiscoverServicesForPeripheral:(CBPeripheral *)peripheral;

/**
 *  扫描到从属蓝牙设备服务特征
 *
 *  @param peripheral 从属蓝牙设备
 *  @param service    扫描到特征的服务
 */
- (void)bleDidDiscoverPeripheral:(CBPeripheral *)peripheral characteristicsforService:(CBService *)service;

/**
 *  从属蓝牙设备信号质量
 *
 *  @param peripheral 从属蓝牙设备
 *  @param rssi RSSI
 */
- (void)bleDidUpdatePeripheral:(CBPeripheral *)peripheral RSSI:(NSNumber *)rssi;

/**
 *  监听从属蓝牙设备特征有新值
 *
 *  @param peripheral 从属蓝牙设备
 *  @param characteristic 从属蓝牙设备特征
 */
- (void)bleDidUpdatePeripheral:(CBPeripheral *)peripheral valueForCharacteristic:(CBCharacteristic *)characteristic;

/**
 *  向从属蓝牙设备发送数据完成
 *
 *  @param peripheral 从属蓝牙设备
 *  @param characteristic 从属蓝牙设备
 *  @param error          错误
 */
- (void)bleDidWritePeripheral:(CBPeripheral *)peripheral valueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error;

/**
 准备好向从属蓝牙发送数据，不必应答回调

 @param peripheral 从属蓝牙设备
 */
- (void)blePeripheralIsReadyToSendWriteWithoutResponse:(CBPeripheral *)peripheral;

/**
 停止蓝牙扫描回调
 */
- (void)bleDidStopScan;

NS_ASSUME_NONNULL_END
@end

