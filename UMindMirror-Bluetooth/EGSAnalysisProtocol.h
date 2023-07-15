//
//  EGSAnalysisProtocol.h
//  EGSSDK
//
//  Created by mopellet on 16/1/11.
//  Copyright © 2016年 EEGSmart. All rights reserved.
//

#ifndef EGSAnalysisProtocol_h
#define EGSAnalysisProtocol_h


@protocol EGSAnalysisProtocol <NSObject>

@optional


/**
 *  获取到脑电设备的脑波原始数据
 *
 *  @param datas NSArray format
 *  @param identifier peripheral.identifier.UUIDString
 */
- (void)didGetRawDatas:(NSArray<NSNumber *> *)datas forIdentifier:(NSString *)identifier;

/**
 *  收到脑电设备信号质量（0~200）
 *
 *  @param signal 噪音的大小（值越大，信号越差）
 *  @param identifier peripheral.identifier.UUIDString
 */
- (void)didGetSignalQuality:(NSInteger)signal forIdentifier:(NSString *)identifier;


/**
 得到充电信息

 @param battery 电量值(0~100)
 @param chargeState 充电状态   0：未充电  1：充电中  2：充电完成  3：从充电器拿出，2秒后自动关机
 @param identifier peripheral.identifier.UUIDString
 */
- (void)didAnalyseBattery:(NSInteger)battery chargeState:(NSInteger)chargeState forIdentifier:(NSString *)identifier;


/// 得到体位和体动等级
/// @param bodyPosition 体位
/// @param bodyMovelLevel 体动等级
/// @param identifier peripheral.identifier.UUIDString
- (void)didAnalyseBodyPosition:(NSInteger )bodyPosition bodyMovelLevel:(NSInteger)bodyMovelLevel forIdentifier:(NSString *)identifier;

/**
 查询硬件版本
 @param hardWare 硬件版本
 @param identifier peripheral.identifier.UUIDString
 */
- (void)didGetHardWareVersion:(NSString *)hardWare forIdentifier:(NSString *)identifier;

/**
 查询软件版本
 
 @param softWare 软件版本
 @param identifier peripheral.identifier.UUIDString
 */
- (void)didGetSoftWareVersion:(NSString *)softWare forIdentifier:(NSString *)identifier;

/**
 查询SN码
 
 @param snCode SN码
 @param identifier peripheral.identifier.UUIDString
 */
- (void)didGetSNVersion:(NSString *)snCode forIdentifier:(NSString *)identifier;


/// 接到同步时间指令
/// @param identifier peripheral.identifier.UUIDString
- (void)didAnalyseUpdateTimeForIdentifier:(NSString *)identifier;


/// 获取到设备关机指令
/// @param type 1:按键 2:低电
/// @param identifier peripheral.identifier.UUIDString
- (void)didGetPowerOffCommandType:(NSInteger)type forIdentifier:(NSString *)identifier;

/**
 蓝牙指令发送超时
 @param cmdType 指令
 @param identifier peripheral.identifier.UUIDString
 */
- (void)didAnalyseBleCmdTimeoutCmdType:(NSInteger)cmdType forIdentifier:(NSString *)identifier;


/// 蓝牙初始化
/// @param result 成功 YES  失败NO
/// @param identifier peripheral.identifier.UUIDString
- (void)didAnalyseBleInitResult:(BOOL)result forIdentifier:(NSString *)identifier;



/// 接到开关指令
/// @param data data description
///  controlType 开关类型
///  value 开关的值 0为开 1为关
/// @param identifier peripheral.identifier.UUIDString
- (void)didAnalyseControlSwitch:(NSDictionary *)data forIdentifier:(NSString *)identifier;



@end

#endif /* EGSAnalysisProtocol_h */
