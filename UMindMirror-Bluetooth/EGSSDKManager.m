//
//  EGSSDKManager.m
//  EGSSDK
//
//  Created by mopellet on 16/1/11.
//  Copyright © 2016年 EEGSmart. All rights reserved.
//

#import "EGSSDKManager.h"
#import "EGSBLEDefines.h"
#import "EGSmartDataParser.h"

#import "EGSControlOrder.h"

#import "CBPeripheral+UUID.h"
#import "CBPeripheral+Property.h"

#import "EGSSDKHelper.h"


#import "EGSBatchOrder.h"


@interface EGSSDKManager () <EGSBLEManagerDelegate, EGSAnalysisProtocol> {
    EGSmartDataParser *_parser;
}

@property (strong, nonatomic) EGSBLEManager *bleManager;
@property (assign, nonatomic) NSInteger noise;

@property (nonatomic, strong) NSTimer *bleCmdTimer;

//用于超时处理
@property (nonatomic, strong) NSTimer *ws20aCmdTimer;

@property (nonatomic, assign) NSInteger cmdCode;//原为ControlType，因需兼容测试开关Type 改为NSInteger 2010-10-30
@property (nonatomic, strong) NSData  *orderData;
@property (nonatomic, assign) NSInteger resendCount;//指令重发次数，单条指令连续发送6次，则抛出问题

//睡眠仪初始化中  初始化流程 硬件版本 -> SN -> 软件版本  -> 同步时间 -> 设备状态 -> 打开脑电 (有报告，不用打开脑电）
@property (nonatomic, assign)BOOL isInitializing;

/// 同步报告每个包包长
@property (nonatomic, assign)NSInteger synReportPackageLen;

@end

@implementation EGSSDKManager

+ (EGSSDKManager *)sharedManager {
    static EGSSDKManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[EGSSDKManager alloc] init];
    });
    
    return _sharedManager;
}

- (void)dealloc {
    
}

- (instancetype)init {
    if (self = [super init]) {
        _bleManager = [[EGSBLEManager alloc] init];
        _bleManager.delegate = self;
    
        _parser = [[EGSmartDataParser alloc] init];
        _parser.delegate = self;
        
        _resendCount = 0;
    }
    return self;
}


#pragma mark - Private
- (void)connectedPeripheral:(CBPeripheral *)peripheral {
    if ([_bleDelegate respondsToSelector:@selector(bleDidConnectPeripheral:)]) {
        [_bleDelegate bleDidConnectPeripheral:peripheral];
    }
}

- (void)disconnectedPeripheral:(CBPeripheral *)peripheral withError:(nullable NSError *)error {
    if ([_bleDelegate respondsToSelector:@selector(bleDidDisconnectPeripheral:withError:)]) {
        [_bleDelegate bleDidDisconnectPeripheral:peripheral withError:error];
    }
}

#pragma mark - Getter

- (BOOL)isConnectedDevice {
    BOOL isConnected = NO;
    for (CBPeripheral *peripheral in _bleManager.connectedPeripherals) {
        if (peripheral.state == CBPeripheralStateConnected) {
            isConnected = YES;
            break;
        }
    }
    return isConnected;
}

#pragma mark - Setter

- (void)setBleDelegate:(id<EGSBLEManagerDelegate>)bleDelegate {
    if ([_bleDelegate isEqual:bleDelegate]) {
        return;
    }
    _bleDelegate = bleDelegate;
}


- (void)setAnalysisDelegate:(id<EGSAnalysisProtocol>)analysisDelegate {
    if ([_analysisDelegate isEqual:analysisDelegate]) {
        return;
    }
    _analysisDelegate = analysisDelegate;
}


/**
 *  发送数据到蓝牙
 *
 *  @param data 一次最多发送20BYTE
 */
- (void)sendByteToBLE:(NSData *)data forIdentifier:(NSString *)identifier {
    CBPeripheral *peripheral = [_bleManager connectedPeripheralWithIdentifier:identifier];
    if (peripheral) {
        [_bleManager writePeripheral:peripheral
                          forService:peripheral.writeServiceUUID
                  characteristicUUID:peripheral.writeCharacteristicUUID
                            withData:data];
    }
}


- (NSData *)generateSleepMeterPackageByCMD:(NSInteger)cmd classType:(NSInteger)classType paramData:(NSData *)paramData {
    //aaaa 0000 0522 05020001 d5
    //DATA包含一个CLASS字段和多个CMD字段。
    //CALSS    CMD1    CMD2    CMDn
    NSMutableData *content = [NSMutableData data];
    [content appendBytes:&classType length:1];
    
    //CMD  TYPE  LEN    PARAM
    NSMutableData *cmdData = [NSMutableData data];
    [cmdData appendBytes:&cmd length:1];
    
    NSInteger paramDataLen = paramData.length;
    [cmdData appendBytes:&paramDataLen length:1];
    [cmdData appendData:paramData];
    
    [content appendData:cmdData];
    
    NSMutableData *order = [[NSMutableData alloc] init];
    //协议头
    int ORDER_HEADER = 0xaa;
    [order appendBytes:&ORDER_HEADER length:1];
    [order appendBytes:&ORDER_HEADER length:1];
    
    int ORDER_TIME = 0x00;//时间,2字节
    [order appendBytes:&ORDER_TIME length:1];
    [order appendBytes:&ORDER_TIME length:1];
    
    NSUInteger len = content.length;
    [order appendBytes:&len length:1];
    //内容
    [order appendData:content];
    
    int checkSum = 0;
    for (int i = 0; i < content.length; i++) {
        NSInteger c = 0;
        [content getBytes:&c range:NSMakeRange(i, 1)];
        checkSum += c;
    }
    
    checkSum = 0xff - (checkSum & 0xff);
    [order appendBytes:&checkSum length:1];
    return order;
}


- (void)sendShutDownForIdentifier:(NSString *)identifier {
    NSData *orderData = [EGSControlOrder closeControlOrder:CONTROL_TYPE_POWER_OFF];
    [self sendByteToBLE:orderData forIdentifier:identifier];
    [self startOrResetBleCmdTimer:CONTROL_TYPE_POWER_OFF sendOrderData:orderData forIdentifier:identifier];
}


#pragma mark - init Device
- (void)startOrResetBleCmdTimer:(NSInteger)controlType sendOrderData:(NSData *)orderData forIdentifier:(NSString *)identifier {
    [self invalidateBleCmdTimer];
    if (!_bleCmdTimer) {
        _bleCmdTimer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(resendBleCommand:) userInfo:identifier repeats:YES];
        self.cmdCode = controlType;
        self.orderData = orderData;
    }
}

- (void)invalidateBleCmdTimer {
    self.resendCount = 0;
    if (_bleCmdTimer) {
        [_bleCmdTimer invalidate];
        _bleCmdTimer = nil;
        self.cmdCode = 0;
        self.orderData = nil;
    }
}

- (void)resendBleCommand:(NSTimer *)bleTimer {
    NSString *identifier = bleTimer.userInfo;
    ControlType controlType = self.cmdCode;
    self.resendCount += 1;
    if (self.resendCount > 6) {
        //抛出初始化失败异常
        [self didAnalyseBleCmdTimeoutCmdType:controlType forIdentifier:identifier];
        [self invalidateBleCmdTimer];
        
        //初始化的命令
        if (controlType == CONTROL_TYPE_INQUIRE_DEVICE_HARDWARE ||
            controlType == CONTROL_TYPE_INQUIRE_DEVICE_SOFTWARE ||
            controlType == CONTROL_TYPE_INQUIRE_DEVICE_SN ||
            controlType == CONTROL_TYPE_UPDATE_TIME ||
            controlType == CONTROL_TYPE_BATCH_CONTROL) {
            if (_analysisDelegate && [_analysisDelegate respondsToSelector:@selector(didAnalyseBleInitResult:forIdentifier:)]) {
                [_analysisDelegate didAnalyseBleInitResult:NO forIdentifier:identifier];
            }
        }
        
        return;
    }
    
    if (!self.cmdCode) {
        [self invalidateBleCmdTimer];
        return;
    } else {
        NSData *data = [NSData dataWithData:self.orderData];
        NSLog(@"超时重发 %zd, %@", controlType, data);
        [self sendByteToBLE:data forIdentifier:identifier];
    }
}

- (void)didAnalyseBleCmdTimeoutCmdType:(NSInteger)cmdType forIdentifier:(NSString *)identifier {
    if (self.analysisDelegate && [self.analysisDelegate respondsToSelector:@selector(didAnalyseBleCmdTimeoutCmdType:forIdentifier:)]) {
        [self.analysisDelegate didAnalyseBleCmdTimeoutCmdType:cmdType forIdentifier:identifier];
    }
}


//初始化流程 硬件版本 -> SN -> 软件版本 -> 同步时间 -> 打开脑电
- (void)queryDeviceHardWareVersionForIdentifier:(NSString *)identifier {
    NSData *data = [EGSControlOrder openControlOrder:CONTROL_TYPE_INQUIRE_DEVICE_HARDWARE];
    [self sendByteToBLE:data forIdentifier:identifier];
    [self startOrResetBleCmdTimer:CONTROL_TYPE_INQUIRE_DEVICE_HARDWARE sendOrderData:data forIdentifier:identifier];
    
}

///设备序列号
- (void)queryDeviceNoForIdentifier:(NSString *)identifier {
    NSData *data = [EGSControlOrder openControlOrder:CONTROL_TYPE_INQUIRE_DEVICE_SN];
    [self sendByteToBLE:data forIdentifier:identifier];
    [self startOrResetBleCmdTimer:CONTROL_TYPE_INQUIRE_DEVICE_SN sendOrderData:data forIdentifier:identifier];
}

- (void)queryDeviceSoftWareVersionForIdentifier:(NSString *)identifier {
    NSData *data = [EGSControlOrder openControlOrder:CONTROL_TYPE_INQUIRE_DEVICE_SOFTWARE];
    [self sendByteToBLE:data forIdentifier:identifier];
    [self startOrResetBleCmdTimer:CONTROL_TYPE_INQUIRE_DEVICE_SOFTWARE sendOrderData:data forIdentifier:identifier];
}

- (void)updateDeviceTimeForIdentifier:(NSString *)identifier {
    NSDate * originalDate = [NSDate date];
    NSTimeZone* destinationTimeZone = [NSTimeZone localTimeZone];
    NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:originalDate];
    NSInteger currentTimeStamp = [originalDate timeIntervalSince1970];
    NSInteger localTimeStamp = currentTimeStamp + destinationGMTOffset;
    
    NSMutableData *order = [[NSMutableData alloc] init];
    int checkSum = 0;
    
    int ORDER_HEADER = 0xaa;
    [order appendBytes:&ORDER_HEADER length:1];
    [order appendBytes:&ORDER_HEADER length:1];
    int ORDER_TIME = 0x00;//时间,2字节
    [order appendBytes:&ORDER_TIME length:1];
    [order appendBytes:&ORDER_TIME length:1];
    Byte byte[4] = {0x07, 0x23, CONTROL_TYPE_UPDATE_TIME,0x04};
    [order appendBytes:byte length:4];
    
    for (int i = 1; i < 4; i++) {
        checkSum += byte[i];
    }
    
    Byte timeByte[4];
    timeByte[0] = 0xff & localTimeStamp;
    timeByte[1] = (0xff00 & localTimeStamp) >> 8;
    timeByte[2] = (0xff0000 & localTimeStamp) >> 16;
    timeByte[3] = (0xff000000 & localTimeStamp) >> 24;
    [order appendBytes:timeByte length:4];
    
    for (int i = 0; i < 4; i++) {
        checkSum += timeByte[i];
    }
    checkSum = 0xff - (checkSum & 0xff);
    [order appendBytes:&checkSum length:1];
    
    [self sendByteToBLE:order forIdentifier:identifier];
    [self startOrResetBleCmdTimer:CONTROL_TYPE_UPDATE_TIME sendOrderData:order forIdentifier:identifier];
}

//开启开关
- (void)openControlDatasForIdentifier:(NSString *)identifier {
    EGSBatchOrder *batchOrder = [EGSBatchOrder new];
    [self openControlDatas:batchOrder forIdentifier:identifier];
}

- (void)openControlDatas:(EGSBatchOrder *)batchOrder forIdentifier:(NSString *)identifier {
    NSMutableData *order = [[NSMutableData alloc] init];
    int checkSum = 0;
    
    int ORDER_HEADER = 0xaa;
    [order appendBytes:&ORDER_HEADER length:1];
    [order appendBytes:&ORDER_HEADER length:1];
    int ORDER_TIME = 0x00;//时间,2字节
    [order appendBytes:&ORDER_TIME length:1];
    [order appendBytes:&ORDER_TIME length:1];
    //data长度 0x08 =  0x22, CONTROL_TYPE_BATCH_CONTROL,0x05 Byte cmdByte[4];
    Byte byte[4] = {0x08, 0x22, CONTROL_TYPE_BATCH_CONTROL,0x05};
    [order appendBytes:byte length:4];
    for (int i = 1; i < 4; i++) {
        checkSum += byte[i];
    }
    
    //    NSString *cmd = @"1111 1111 1111 1111 0001 0101 0100 1111";//正常模式的，不需要心率血氧原始数据
    //    NSString *cmd = @"1111 1111 1111 1111 000 1010 0010 0111 1";//2018-11-05 打开心率血氧原始数据
    
    NSString *cmd = [batchOrder getBatchOrder];
    NSString *decimalStr = [[self class] convertDecimalSystemFromBinarySystem:cmd];
    NSInteger batchControl = decimalStr.integerValue;
    
    Byte cmdByte[4];
    cmdByte[0] = 0xff & batchControl;
    cmdByte[1] = (0xff00 & batchControl) >> 8;
    cmdByte[2] = (0xff0000 & batchControl) >> 16;
    cmdByte[3] = (0xff000000 & batchControl) >> 24;
    [order appendBytes:cmdByte length:4];
    for (int i = 0; i < 4; i++) {
        checkSum += cmdByte[i];
    }
    
    int CONTROL_SWITCH = 0x00;
    [order appendBytes:&CONTROL_SWITCH length:1];
    
    checkSum = 0xff - (checkSum & 0xff);
    [order appendBytes:&checkSum length:1];
    
    [self sendByteToBLE:order forIdentifier:identifier];
    [self startOrResetBleCmdTimer:CONTROL_TYPE_BATCH_CONTROL sendOrderData:order forIdentifier:identifier];
}


/// 设置陷波器
/// - Parameters:
///   - isOn: 是否打开
///   - type: 1:50Hz , 2:60Hz
///   - identifier: <#identifier description#>
- (void)openHertzTrap:(BOOL)isOn type:(NSInteger)type forIdentifier:(NSString *)identifier {
    NSMutableData *paramData = [NSMutableData data];
    //[0]：预留。
    NSInteger iFirst = 0;
    if (isOn) {
        iFirst = 0;
    } else {
        iFirst = 1;
    }
    
    [paramData appendBytes:&iFirst length:1];
    //代表请求方或者应答方，此时固定为0。0：请求 1：应答
    NSInteger iAsk = 0;
    [paramData appendBytes:&iAsk length:1];
    
    NSInteger cmd;
    if (type == 1) {
        cmd = CONTROL_TYPE_FIR_FILTER;
    } else {
        cmd = CONTROL_TYPE_NOTCH_60HZ_FILTER;
    }
    
    NSData *orderData = [self generateSleepMeterPackageByCMD:cmd classType:0x22 paramData:paramData];
    [self sendByteToBLE:orderData forIdentifier:identifier];
}

#pragma mark 二进制转十进制
+ (NSString *)convertDecimalSystemFromBinarySystem:(NSString *)binary {
    NSInteger ll = 0 ;
    NSInteger  temp = 0 ;
    for (NSInteger i = 0; i < binary.length; i ++){
        
        temp = [[binary substringWithRange:NSMakeRange(i, 1)] intValue];
        temp = temp * powf(2, binary.length - i - 1);
        ll += temp;
    }
    
    NSString * result = @(ll).stringValue;
    
    return result;
}



#pragma mark - EGSBLEManagerDelegate
- (void)bleCentralManagerDidUpdateState:(CBManagerState)state {
    if ([_bleDelegate respondsToSelector:@selector(bleCentralManagerDidUpdateState:)]) {
        [_bleDelegate bleCentralManagerDidUpdateState:state];
    }
}

- (void)bleDidDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    if ([_bleDelegate respondsToSelector:@selector(bleDidDiscoverPeripheral:advertisementData:RSSI:)]) {
        [_bleDelegate bleDidDiscoverPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
    }
}

- (void)bleDidConnectPeripheral:(CBPeripheral *)peripheral {
    [self connectedPeripheral:peripheral];
    //当前每种设备只能连一台
    if ([EGSSDKHelper isSMMYPeripheral:peripheral]) {
        self.isInitializing = YES;
        [_parser removeBufferForIdentifier:nil];
    }
    _resendCount = 0;
}

- (void)bleDidFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    if ([_bleDelegate respondsToSelector:@selector(bleDidFailToConnectPeripheral:error:)]) {
        [_bleDelegate bleDidFailToConnectPeripheral:peripheral error:error];
    }
}

- (void)bleDidDisconnectPeripheral:(CBPeripheral *)peripheral withError:(nullable NSError *)error{
    [self invalidateBleCmdTimer];
    [self disconnectedPeripheral:peripheral withError:error];
}

- (void)bleDidDiscoverServicesForPeripheral:(CBPeripheral *)peripheral {
    if ([_bleDelegate respondsToSelector:@selector(bleDidDiscoverServicesForPeripheral:)]) {
        [_bleDelegate bleDidDiscoverServicesForPeripheral:peripheral];
    }
}

- (void)bleDidDiscoverPeripheral:(CBPeripheral *)peripheral characteristicsforService:(CBService *)service {
    if ([_bleDelegate respondsToSelector:@selector(bleDidDiscoverPeripheral:characteristicsforService:)]) {
        [_bleDelegate bleDidDiscoverPeripheral:peripheral characteristicsforService:service];
    }
    for (CBUUID *EEGSmartServiceUUID in [EGSBLEManager allSupportedServiceUUIDs]) {
        if ([service.UUID.UUIDString isEqualToString:EEGSmartServiceUUID.UUIDString]) {
            peripheral.writeServiceUUID = EEGSmartServiceUUID;
            
            if ([EGSSDKHelper isSMMYPeripheral:peripheral]) {
                peripheral.writeCharacteristicUUID = [CBUUID UUIDWithString:@EGSBL_CHAR_W_UUID];
                [self queryDeviceHardWareVersionForIdentifier:peripheral.identifier.UUIDString];
            }
            break;
        }
    }
}

- (void)bleDidUpdatePeripheral:(CBPeripheral *)peripheral RSSI:(NSNumber *)rssi {
    if (self.analysisDelegate && [self.analysisDelegate respondsToSelector:@selector(bleDidUpdatePeripheral:RSSI:)]) {
        [_bleDelegate bleDidUpdatePeripheral:peripheral RSSI:rssi];
    }
}

- (void)bleDidUpdatePeripheral:(CBPeripheral *)peripheral valueForCharacteristic:(CBCharacteristic *)characteristic {
    if (self.analysisDelegate && [self.analysisDelegate respondsToSelector:@selector(bleDidUpdatePeripheral:valueForCharacteristic:)]) {
        [_bleDelegate bleDidUpdatePeripheral:peripheral valueForCharacteristic:characteristic];
    }
    
    if ([EGSSDKHelper isSMMYPeripheral:peripheral]){
        [_parser parseData:characteristic.value forIdentifier:peripheral.identifier.UUIDString];
    }
}

- (void)bleDidWritePeripheral:(CBPeripheral *)peripheral valueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if ([_bleDelegate respondsToSelector:@selector(bleDidWritePeripheral:valueForCharacteristic:error:)]) {
        [_bleDelegate bleDidWritePeripheral:peripheral valueForCharacteristic:characteristic error:error];
    }
}

- (void)blePeripheralIsReadyToSendWriteWithoutResponse:(CBPeripheral *)peripheral {
    if ([_bleDelegate respondsToSelector:@selector(blePeripheralIsReadyToSendWriteWithoutResponse:)]) {
        [_bleDelegate blePeripheralIsReadyToSendWriteWithoutResponse:peripheral];
    }
}

- (void)bleDidStopScan {
    if (_bleDelegate && [_bleDelegate respondsToSelector:@selector(bleDidStopScan)]) {
        [_bleDelegate bleDidStopScan];
    }
}

#pragma mark - EGSAnalysisProtocol

- (void)didGetRawDatas:(NSArray *)datas forIdentifier:(NSString *)identifier {
    if (self.analysisDelegate && [self.analysisDelegate respondsToSelector:@selector(didGetRawDatas:forIdentifier:)]) {
        [_analysisDelegate didGetRawDatas:datas forIdentifier:identifier];
    }
}

- (void)didGetSignalQuality:(NSInteger)signal forIdentifier:(NSString *)identifier {
    if (self.analysisDelegate && [self.analysisDelegate respondsToSelector:@selector(didGetSignalQuality:forIdentifier:)]) {
        [_analysisDelegate didGetSignalQuality:signal forIdentifier:identifier];
    }
    _noise = signal;
}


- (void)didAnalyseBattery:(NSInteger)battery chargeState:(NSInteger)chargeState forIdentifier:(NSString *)identifier {
    CBPeripheral *peripheral = [EGSSDKHelper connectedPeripheralWithIdentifier:identifier];
    if (peripheral) {
        peripheral.chargeState = chargeState;
        peripheral.batVal = @(battery);
    }
    
    if (self.analysisDelegate && [self.analysisDelegate respondsToSelector:@selector(didAnalyseBattery:chargeState:forIdentifier:)]) {
        [_analysisDelegate didAnalyseBattery:battery chargeState:chargeState forIdentifier:identifier];
    }
}

- (void)didAnalyseControlSwitch:(NSDictionary *)data forIdentifier:(NSString *)identifier {
    ControlType controlType ;
    controlType = (ControlType)[[data objectForKey:@"controlType"] intValue];
    id value;
    
    if ([data objectForKey:@"value"]) {
        value = [data objectForKey:@"value"];
    }
    
    if (_analysisDelegate && [_analysisDelegate respondsToSelector:@selector(didAnalyseControlSwitch:forIdentifier:)]) {
        [_analysisDelegate didAnalyseControlSwitch:data forIdentifier:identifier];
    }
    
    //组合控制开关
    if (controlType == CONTROL_TYPE_BATCH_CONTROL) {
        [self invalidateBleCmdTimer];
        
        if (self.isInitializing) {
            [self sleepMeterInitializedSucceed:identifier];
        }
    }
}


#pragma mark - 硬件版本回调
///硬件版本
- (void)didGetHardWareVersion:(NSString *)hardWare forIdentifier:(NSString *)identifier {
    if (self.cmdCode == CONTROL_TYPE_INQUIRE_DEVICE_HARDWARE) {
        //加此判断是为了防止，设备延时返回严重，导致多次收到消息
        [self invalidateBleCmdTimer];
        [self queryDeviceNoForIdentifier:identifier];
    }
    
    if (_analysisDelegate && [_analysisDelegate respondsToSelector:@selector(didGetHardWareVersion:forIdentifier:)]) {
        [_analysisDelegate didGetHardWareVersion:hardWare forIdentifier:identifier];
    }
}

#pragma mark - 软件版本
- (void)didGetSoftWareVersion:(NSString *)softWare forIdentifier:(NSString *)identifier {
    if (self.cmdCode == CONTROL_TYPE_INQUIRE_DEVICE_SOFTWARE) {
        //加此判断是为了防止，设备延时返回严重，导致多次收到消息
        [self invalidateBleCmdTimer];
        [self updateDeviceTimeForIdentifier:identifier];
    }
    if (_analysisDelegate && [_analysisDelegate respondsToSelector:@selector(didGetSoftWareVersion:forIdentifier:)]) {
        [_analysisDelegate didGetSoftWareVersion:softWare forIdentifier:identifier];
    }
}

#pragma mark - SN
- (void)didGetSNVersion:(NSString *)snCode forIdentifier:(NSString *)identifier {
    CBPeripheral *peripheral = [EGSSDKHelper connectedPeripheralWithIdentifier:identifier];
    if (peripheral) {
        peripheral.snCode = snCode;
    }
    
    if (self.cmdCode == CONTROL_TYPE_INQUIRE_DEVICE_SN) {
        //加此判断是为了防止，设备延时返回严重，导致多次收到消息
        [self invalidateBleCmdTimer];
        [self queryDeviceSoftWareVersionForIdentifier:identifier];
        
    }
    if (_analysisDelegate && [_analysisDelegate respondsToSelector:@selector(didGetSNVersion:forIdentifier:)]) {
        [_analysisDelegate didGetSNVersion:snCode forIdentifier:identifier];
    }
}

#pragma mark - 同步时间 同步数据超时等待判断
- (void)didAnalyseUpdateTimeForIdentifier:(NSString *)identifier {
    [self invalidateBleCmdTimer];
    [self openControlDatasForIdentifier:identifier];
}


- (void)didGetPowerOffCommandType:(NSInteger)type forIdentifier:(NSString *)identifier {
    if (_analysisDelegate && [_analysisDelegate respondsToSelector:@selector(didGetPowerOffCommandType:forIdentifier:)]) {
        [_analysisDelegate didGetPowerOffCommandType:type forIdentifier:identifier];
    }
}

- (void)didAnalyseBodyPosition:(NSInteger)bodyPosition bodyMovelLevel:(NSInteger)bodyMovelLevel forIdentifier:(NSString *)identifier {
    if (_analysisDelegate && [_analysisDelegate respondsToSelector:@selector(didAnalyseBodyPosition:bodyMovelLevel:forIdentifier:)]) {
        [_analysisDelegate didAnalyseBodyPosition:bodyPosition bodyMovelLevel:bodyMovelLevel forIdentifier:identifier];
    }
}


///睡眠仪初始化成功
- (void)sleepMeterInitializedSucceed:(NSString *)identifier {
    self.isInitializing = NO;
    if (_analysisDelegate && [_analysisDelegate respondsToSelector:@selector(didAnalyseBleInitResult:forIdentifier:)]) {
        [_analysisDelegate didAnalyseBleInitResult:YES forIdentifier:identifier];
    }
}

@end
