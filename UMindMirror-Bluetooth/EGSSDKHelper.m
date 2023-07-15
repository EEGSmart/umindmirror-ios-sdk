//
//  EGSSDKHelper.m
//  EGSSDK
//
//  Created by mopellet on 17/4/7.
//  Copyright © 2017年 EEGSmart. All rights reserved.
//

#import "EGSSDKHelper.h"
#import "EGSSDKManager.h"

#import "CBPeripheral+Property.h"

#define LastPairedDeviceIdentifier @"lastConnectedDeviceIdentifier"

@interface EGSSDKHelper()<EGSSDKHelperProtocol>

@property (nonatomic, strong) NSHashTable *serverDelegates;
@property (nonatomic, assign) NSInteger noiseValue;
@property (nonatomic, weak) NSTimer *scanTimer;
@property (nonatomic, strong) EGSSDKManager *sdkManager;

@end


@implementation EGSSDKHelper

+ (instancetype)sharedHelper {
    static id singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[[self class] alloc] init];
    });
    return singleton;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _serverDelegates = [NSHashTable weakObjectsHashTable];
        _sdkManager = [EGSSDKManager sharedManager];
        _sdkManager.analysisDelegate = self;
        _sdkManager.bleDelegate = self;
    }
    return self;
}



- (BOOL)isConnectDevice {
    return self.sdkManager.isConnectedDevice;
}

- (NSArray<CBPeripheral *> *)connectedPeripherals {
    return self.sdkManager.bleManager.connectedPeripherals;
}

- (NSArray<CBPeripheral *> *)peripherals {
    return self.sdkManager.bleManager.peripherals;
}

- (CBPeripheral *)umindPeripheral {
    if (self.connectedPeripherals.count) {
        for (CBPeripheral *peripheral in self.connectedPeripherals) {
            if ([EGSSDKHelper isSMMYPeripheral:peripheral]) {
                return peripheral;
            }
        }
    }
    return nil;
}


- (CBManagerState)state {
    return (CBManagerState)self.sdkManager.bleManager.centraManager.state;
}


- (void)addServerDelegate:(id<EGSSDKHelperProtocol>)delegate {
    @synchronized (self.serverDelegates) {
        if ([delegate conformsToProtocol:@protocol(EGSSDKHelperProtocol)]) {
            [self.serverDelegates addObject:delegate];
        }
    }
}

- (void)removeServerDelegate:(id<EGSSDKHelperProtocol>)delegate {
    @synchronized (self.serverDelegates) {
        if ([delegate conformsToProtocol:@protocol(EGSSDKHelperProtocol)]) {
            [self.serverDelegates removeObject:delegate];
        }
    }
}

- (void)removeAllServerDelegate {
    @synchronized (self.serverDelegates) {
        [self.serverDelegates removeAllObjects];
    }
}


#pragma mark - 蓝牙相关
- (void)startDiscoveringDevices:(BOOL)isAutoConnect {
    if (isAutoConnect) {
        [self autoLinkDevice];
    } else {
        [[EGSSDKManager sharedManager].bleManager scanPeripheralsWithServices:[EGSBLEManager allSupportedServiceUUIDs]
                                                                      timeout:10];
    }
}


- (void)stopScan {
    [self stopScanTimer];
    [[EGSSDKManager sharedManager].bleManager stopScan];
}


- (void)autoLinkDevice {
    if (!self.scanTimer) {
        self.scanTimer = [NSTimer scheduledTimerWithTimeInterval:(float)9.0 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
    }
    
    EGSBLEManager *bleManager = [EGSSDKManager sharedManager].bleManager;
    [bleManager scanPeripheralsWithServices:[EGSBLEManager allSupportedServiceUUIDs]
                                    timeout:10];
}

- (void)connectionTimer:(NSTimer *)timer {
    NSLog(@"%s",__func__);
   
    if (self.peripherals.count > 0) {
        [self stopScan];
        
        NSString *UUIDString = [[self class] lastPairedDeviceIdentifier];
        if (UUIDString) {//已连接过
            for (CBPeripheral *peripheral in self.peripherals) {
                if ([peripheral.identifier.UUIDString isEqualToString:UUIDString]) {
                    if (peripheral.chargeState == 0) {
                        NSLog(@"开始重新连接上次已经连接的");
                        [self connectPeripheral:peripheral];
                    }
                    break;
                }
            }
        }
    }
}



- (void)connectPeripheral:(CBPeripheral *)peripheral {
    if ([[self class] isSMMYPeripheral:peripheral]) {
        [[self class] setLastPairedDeviceIdentifier:peripheral.identifier.UUIDString];
    } else { //以后添加设备在此改
        [[self class] setLastPairedDeviceIdentifier:peripheral.identifier.UUIDString];
    }
    [self.sdkManager.bleManager connectPeripheral:peripheral];
}


- (void)disConnectPeripheral:(CBPeripheral *)peripheral {
    [self.sdkManager.bleManager cancelPeripheralConnection:peripheral];
    _snCode = @"";
    _softWare = @"";
    _hardWare = @"";
}


- (void)openControlDatasForIdentifier:(NSString *)identifier {
    [self.sdkManager openControlDatasForIdentifier:identifier];
}

- (void)openControlDatas:(EGSBatchOrder *)batchOrder forIdentifier:(NSString *)identifier {
    [self.sdkManager openControlDatas:batchOrder forIdentifier:identifier];
}

- (void)openHertzTrap:(BOOL)isOn type:(NSInteger)type forIdentifier:(NSString *)identifier {
    [self.sdkManager openHertzTrap:isOn type:type forIdentifier:identifier];
}



#pragma mark - EGSAnalysisProtocol

- (void)didGetSignalQuality:(NSInteger)signal forIdentifier:(NSString *)identifier {
    self.noiseValue = signal;
    @synchronized (self.serverDelegates) {
        for (id delegate in self.serverDelegates) {
            if ([delegate respondsToSelector:@selector(didGetSignalQuality:forIdentifier:)] ) {
                [delegate didGetSignalQuality:signal forIdentifier:identifier];
            }
        }
    }
}

- (void)didGetRawDatas:(NSArray<NSNumber *> *)datas forIdentifier:(NSString *)identifier {
    @synchronized (self.serverDelegates) {
        NSHashTable *hashTable = [self.serverDelegates mutableCopy];
        for (id delegate in hashTable) {
            if ([delegate respondsToSelector:@selector(didGetRawDatas:forIdentifier:)] ) {
                [delegate didGetRawDatas:datas forIdentifier:identifier];
            }
        }
    }
}


/// 得到充电信息
/// - Parameters:
///   - battery: 电量值(0~100)
///   - chargeState: 充电状态   0：未充电  1：充电中  2：充电完成  3：从充电器拿出，2秒后自动关机
///   - identifier: peripheral.identifier.UUIDString
- (void)didAnalyseBattery:(NSInteger)battery chargeState:(NSInteger)chargeState forIdentifier:(NSString *)identifier {
    _battery = battery;
    @synchronized (self.serverDelegates) {
        for (id delegate in self.serverDelegates) {
            if ([delegate respondsToSelector:@selector(didAnalyseBattery:chargeState:forIdentifier:)]) {
                [delegate didAnalyseBattery:battery chargeState:chargeState forIdentifier:identifier];
            }
        }
    }
}

- (void)didAnalyseBleCmdTimeoutCmdType:(NSInteger)cmdType forIdentifier:(NSString *)identifier {
    @synchronized (self.serverDelegates) {
        for (id delegate in self.serverDelegates) {
            if ([delegate respondsToSelector:@selector(didAnalyseBleCmdTimeoutCmdType:forIdentifier:)]) {
                [delegate didAnalyseBleCmdTimeoutCmdType:cmdType forIdentifier:identifier];
            }
        }
    }
}



- (void)didAnalyseControlSwitch:(NSDictionary *)data forIdentifier:(NSString *)identifier {
    @synchronized (self.serverDelegates) {
        for (id delegate in self.serverDelegates) {
            if ([delegate respondsToSelector:@selector(didAnalyseControlSwitch:forIdentifier:)] ) {
                [delegate didAnalyseControlSwitch:data forIdentifier:identifier];
            }
        }
    }
}


- (void)didAnalyseBodyPosition:(NSInteger)bodyPosition
                bodyMovelLevel:(NSInteger)bodyMovelLevel
                 forIdentifier:(NSString *)identifier {
    @synchronized (self.serverDelegates) {
        for (id delegate in self.serverDelegates) {
            if ([delegate respondsToSelector:@selector(didAnalyseBodyPosition:bodyMovelLevel:forIdentifier:)] ) {
                [delegate didAnalyseBodyPosition:bodyPosition bodyMovelLevel:bodyMovelLevel forIdentifier:identifier];
            }
        }
    }
}


- (void)didAnalyseBleInitResult:(BOOL)result forIdentifier:(NSString *)identifier {
    @synchronized (self.serverDelegates) {
        for (id delegate in self.serverDelegates) {
            if ([delegate respondsToSelector:@selector(didAnalyseBleInitResult:forIdentifier:)] ) {
                [delegate didAnalyseBleInitResult:result forIdentifier:identifier];
            }
        }
    }
}

- (void)didGetHardWareVersion:(NSString *)hardWare forIdentifier:(NSString *)identifier {
    @synchronized (self.serverDelegates) {
        _hardWare = hardWare;
        for (id delegate in self.serverDelegates) {
            if ([delegate respondsToSelector:@selector(didGetHardWareVersion:forIdentifier:)] ) {
                [delegate didGetHardWareVersion:hardWare forIdentifier:identifier];
            }
        }
    }
}

- (void)didGetSoftWareVersion:(NSString *)softWare forIdentifier:(NSString *)identifier {
    @synchronized (self.serverDelegates) {
        _softWare = softWare;
        for (id delegate in self.serverDelegates) {
            if ([delegate respondsToSelector:@selector(didGetSoftWareVersion:forIdentifier:)] ) {
                [delegate didGetSoftWareVersion:softWare forIdentifier:identifier];
            }
        }
    }
}

- (void)didGetSNVersion:(NSString *)snCode forIdentifier:(NSString *)identifier{
    @synchronized (self.serverDelegates) {
        _snCode = snCode;
        for (id delegate in self.serverDelegates) {
            if ([delegate respondsToSelector:@selector(didGetSNVersion:forIdentifier:)] ) {
                [delegate didGetSNVersion:snCode forIdentifier:identifier];
            }
        }
    }
}


///获得到关机信息
- (void)didGetPowerOffCommandType:(NSInteger)type forIdentifier:(NSString *)identifier {
    @synchronized (self.serverDelegates) {
        for (id delegate in self.serverDelegates) {
            if ([delegate respondsToSelector:@selector(didGetPowerOffCommandType:forIdentifier:)] ) {
                [delegate didGetPowerOffCommandType:type forIdentifier:identifier];
            }
        }
    }
}


#pragma mark - EGSBLEManagerDelegate
- (void)bleDidConnectPeripheral:(nullable CBPeripheral *)peripheral {
    @synchronized (self.serverDelegates) {
        for (id delegate in self.serverDelegates) {
            if ([delegate respondsToSelector:@selector(bleDidConnectPeripheral:)] ) {
                [delegate bleDidConnectPeripheral:peripheral];
            }
        }
        _noiseValue = 200;
    }
}

- (void)bleDidDisconnectPeripheral:(nullable CBPeripheral *)peripheral
                         withError:(nullable NSError *)error {
    @synchronized (self.serverDelegates) {
        NSLog(@"断开原因 %@ ",error);
        for (id delegate in self.serverDelegates) {
            if ([delegate respondsToSelector:@selector(bleDidDisconnectPeripheral:withError:)] ) {
                [delegate bleDidDisconnectPeripheral:peripheral withError:error];
            }
        }
        
        if (error) {
            NSLog(@"3s后启动断线重连");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                [self autoLinkDevice];
            });
        }
    }
}

- (void)bleCentralManagerDidUpdateState:(CBManagerState)state {
    @synchronized (self.serverDelegates) {
        for (id delegate in self.serverDelegates) {
            if ([delegate respondsToSelector:@selector(bleCentralManagerDidUpdateState:)] ) {
                [delegate bleCentralManagerDidUpdateState:state];
            }
        }
    }
}

- (void)bleDidDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(nonnull NSNumber *)RSSI{
    @synchronized (self.serverDelegates) {
        for (id delegate in self.serverDelegates) {
            if ([delegate respondsToSelector:@selector(bleDidDiscoverPeripheral:advertisementData:RSSI:)] ) {
                [delegate bleDidDiscoverPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
            }
        }
    }
}

- (void)bleDidDiscoverServicesForPeripheral:(CBPeripheral *)peripheral {
    @synchronized (self.serverDelegates) {
        for (id delegate in self.serverDelegates) {
            if ([delegate respondsToSelector:@selector(bleDidDiscoverServicesForPeripheral:)] ) {
                [delegate bleDidDiscoverServicesForPeripheral:peripheral];
            }
        }
    }
}

- (void)bleDidDiscoverPeripheral:(CBPeripheral *)peripheral characteristicsforService:(CBService *)service {
    @synchronized (self.serverDelegates) {
        for (id delegate in self.serverDelegates) {
            if ([delegate respondsToSelector:@selector(bleDidDiscoverPeripheral:characteristicsforService:)] ) {
                [delegate bleDidDiscoverPeripheral:peripheral characteristicsforService:service];
            }
        }
    }
}

- (void)bleDidUpdatePeripheral:(CBPeripheral *)peripheral RSSI:(NSNumber *)rssi {
    @synchronized (self.serverDelegates) {
        for (id delegate in self.serverDelegates) {
            if ([delegate respondsToSelector:@selector(bleDidUpdatePeripheral:RSSI:)]) {
                [delegate bleDidUpdatePeripheral:peripheral RSSI:rssi];
            }
        }
    }
}

- (void)bleDidUpdatePeripheral:(CBPeripheral *)peripheral valueForCharacteristic:(CBCharacteristic *)characteristic {
    @synchronized (self.serverDelegates) {
        for (id delegate in self.serverDelegates) {
            if ([delegate respondsToSelector:@selector(bleDidUpdatePeripheral:valueForCharacteristic:)] ) {
                [delegate bleDidUpdatePeripheral:peripheral valueForCharacteristic:characteristic];
            }
        }
    }
}


- (void)bleDidWritePeripheral:(CBPeripheral *)peripheral valueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    @synchronized (self.serverDelegates) {
        for (id delegate in self.serverDelegates) {
            if ([delegate respondsToSelector:@selector(bleDidWritePeripheral:valueForCharacteristic:error:)] ) {
                [delegate bleDidWritePeripheral:peripheral valueForCharacteristic:characteristic error:error];
            }
        }
    }
}

- (void)blePeripheralIsReadyToSendWriteWithoutResponse:(CBPeripheral *)peripheral {
    @synchronized (self.serverDelegates) {
        for (id delegate in self.serverDelegates) {
            if ([delegate respondsToSelector:@selector(blePeripheralIsReadyToSendWriteWithoutResponse:)]) {
                [delegate blePeripheralIsReadyToSendWriteWithoutResponse:peripheral];
            }
        }
    }
}

- (void)bleDidStopScan {
    @synchronized (self.serverDelegates) {
        for (id delegate in self.serverDelegates) {
            if ([delegate respondsToSelector:@selector(bleDidStopScan)]) {
                [delegate bleDidStopScan];
            }
        }
    }
}


#pragma mark -Other
- (NSString *)lastConnectedDeviceIdentifier {
    return [[self class] lastPairedDeviceIdentifier];
}

+ (NSString *)lastPairedDeviceIdentifier {
    return [[NSUserDefaults standardUserDefaults] objectForKey:LastPairedDeviceIdentifier];
}

+ (void)setLastPairedDeviceIdentifier:(NSString *)identifier {
    [[NSUserDefaults standardUserDefaults] setObject:identifier forKey:LastPairedDeviceIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)removeLastPairedDeviceIdentifier {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:LastPairedDeviceIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
}



- (void)stopScanTimer {
    if (self.scanTimer) {
        [self.scanTimer invalidate];
        self.scanTimer = nil;
    }
}


+ (BOOL)isSMMYPeripheral:(CBPeripheral *)peripheral {
    //以前名称 umindsleep cateye
    if ([[peripheral.name lowercaseString] hasPrefix:@"smmy"] || [[peripheral.name lowercaseString] hasPrefix:@"cateye"] || [[peripheral.name lowercaseString] hasPrefix:@"umindsleep"] || [[peripheral.name lowercaseString] hasPrefix:@"umindmirror"]) {
        return YES;
    }
    return NO;
}


+ (CBPeripheral *)connectedPeripheralWithIdentifier:(NSString *)identifier {
    for (CBPeripheral *peripheral in SDKHelper.connectedPeripherals) {
        if ([peripheral.identifier.UUIDString isEqualToString:identifier]) {
            return peripheral;
        }
    }
    return nil;
}


+ (BOOL)isSleeperModelC1:(NSString *)snCode {
    if([snCode hasPrefix:@"C1"] || [snCode hasPrefix:@"H1"] || [snCode hasPrefix:@"CE"] || [snCode hasPrefix:@"UM"]) {
        return YES;
    }
    return NO;
}

+ (BOOL)isSleeperModelS1:(NSString *)snCode {
    if([snCode hasPrefix:@"S1"]) {
        return YES;
    }
    return NO;
}

+ (BOOL)isSleeperModelE1:(NSString *)snCode {
    if([snCode hasPrefix:@"E1"]) {
        return YES;
    }
    return NO;
}


@end
