//
//  ESBLEManager.m
//  EGSSDK
//
//  Created by mopellet on 15/12/23.
//  Copyright © 2015年 EEGSmart. All rights reserved.
//

#import "EGSBLEManager.h"
#import "EGSBLEDefines.h"

#import "CBPeripheral+Property.h"
#import "EGSSDKHelper.h"

@interface EGSBLEManager ()
@property (strong, nonatomic) NSMutableArray *peripherals;

@property (strong, nonatomic, nullable) NSMutableArray<CBPeripheral *> *connectedPeripherals;

@end

@implementation EGSBLEManager

#pragma mark - Life Cycle

- (void)dealloc {
    NSLog(@"EGSBLEManager dealloc");
    [self cancelPeripheralConnection:nil];
}

- (instancetype)init {
    if (self = [super init]) {
        _centraManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    return self;
}

#pragma mark - Public

- (CBPeripheral *)connectedPeripheralWithIdentifier:(NSString *)identifier {
    for (CBPeripheral *peripheral in self.connectedPeripherals) {
        if ([peripheral.identifier.UUIDString isEqualToString:identifier]) {
            return peripheral;
        }
    }
    return nil;
}


- (NSMutableArray<CBPeripheral *> *)connectedPeripherals {
    if (!_connectedPeripherals) {
        _connectedPeripherals = [[NSMutableArray alloc] init];
    }
    return _connectedPeripherals;
}

- (BOOL)scanPeripheralsWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs
                            timeout:(NSTimeInterval)timeout {
    if (_centraManager.state != CBManagerStatePoweredOn) {
        return NO;
    }
    
    if (_peripherals) {
        [_peripherals removeAllObjects];
    }
    
    if (_connecting) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [NSTimer scheduledTimerWithTimeInterval:(float)timeout target:self selector:@selector(scanTimeout:) userInfo:nil repeats:NO];
            //设置同一个蓝牙允许重复发现
            [_centraManager scanForPeripheralsWithServices:serviceUUIDs options:@{CBCentralManagerScanOptionAllowDuplicatesKey:[NSNumber numberWithBool:NO]}];
        });
    } else {
        [NSTimer scheduledTimerWithTimeInterval:(float)timeout target:self selector:@selector(scanTimeout:) userInfo:nil repeats:NO];
        //设置同一个蓝牙允许重复发现
        [_centraManager scanForPeripheralsWithServices:serviceUUIDs options:@{CBCentralManagerScanOptionAllowDuplicatesKey:[NSNumber numberWithBool:NO]}];
    }
    
    return YES; // Started scanning OK !
}

// 停止扫描从属蓝牙设备
- (void)stopScan {
    [_centraManager stopScan];
}

- (BOOL)scanPeripheralsWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs {
    if (_centraManager.state != CBManagerStatePoweredOn) {
        return NO;
    }
    
    if (_peripherals) {
        [_peripherals removeAllObjects];
    }
    
    NSDictionary *options = @{CBCentralManagerScanOptionAllowDuplicatesKey:[NSNumber numberWithBool:NO]};
    
    if (_connecting) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_centraManager scanForPeripheralsWithServices:serviceUUIDs options:options];
        });
    } else {
        [_centraManager scanForPeripheralsWithServices:serviceUUIDs options:options];
    }
    
    return YES;
}


- (void)connectPeripheral:(CBPeripheral *)peripheral {

    BOOL connectedPeripheral = [self peripheralInConnected:peripheral];
    if (connectedPeripheral && peripheral.state == CBPeripheralStateConnected) {
        return;
    }
    
    NSDictionary *options = @{CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES,
                              CBConnectPeripheralOptionNotifyOnConnectionKey:@YES,
//                              CBConnectPeripheralOptionNotifyOnNotificationKey:@YES
                              };
    [_centraManager connectPeripheral:peripheral options:options];
    _connecting = YES;
    _connectingPeripheral = peripheral;
}

- (void)cancelPeripheralConnection:(CBPeripheral *)peripheral {
    if (peripheral) {
        [self disconnectPeripheral:peripheral];
    } else {
        NSArray *peripherals = [self.connectedPeripherals copy];
        for (CBPeripheral *mPeripheral in peripherals) {
            [self disconnectPeripheral:mPeripheral];
        }
    }
}

- (void)disconnectPeripheral:(CBPeripheral *)peripheral {
    if (peripheral.state == CBPeripheralStateConnected) {
        for (CBService * service in peripheral.services) {
            if (service.characteristics) {
                for (CBCharacteristic * characteristic in service.characteristics) {
                    if (characteristic.isNotifying) {
                        //取消
                        [peripheral setNotifyValue:NO forCharacteristic:characteristic];
                        break;
                    }
                }
            }
        }
        
        [_centraManager cancelPeripheralConnection:peripheral];
    }
    peripheral.delegate = nil;
    [self.connectedPeripherals removeObject:peripheral];
}

- (void)notifyPeripheral:(CBPeripheral *)p on:(BOOL)on forService:(CBUUID *)sUUID characteristicUUID:(CBUUID *)cUUID {
    CBService *service = [self searchPeripheral:p serviceWithUUID:sUUID];
    if (!service) {
        return;
    }
    
    CBCharacteristic *characteristic = [self searchCharacteristicWithUUID:cUUID inService:service];
    if (!characteristic) {
        return;
    }
    
    [p setNotifyValue:on forCharacteristic:characteristic];
}

- (void)readPeripheral:(CBPeripheral *)p valueForService:(CBUUID *)sUUID characteristicUUID:(CBUUID *)cUUID {
    CBService *service = [self searchPeripheral:p serviceWithUUID:sUUID];
    if (!service) {
        return;
    }
    
    CBCharacteristic *characteristic = [self searchCharacteristicWithUUID:cUUID inService:service];
    if (!characteristic) {
        return;
    }
    
    [p readValueForCharacteristic:characteristic];
}

- (void)writePeripheral:(CBPeripheral *)p forService:(CBUUID *)sUUID characteristicUUID:(CBUUID *)cUUID withData:(NSData *)data {
    CBService *service = [self searchPeripheral:p serviceWithUUID:sUUID];
    if (!service) {
        return;
    }
    
    CBCharacteristic *characteristic = [self searchCharacteristicWithUUID:cUUID inService:service];
    if (!characteristic) {
        return;
    }
    //发送不需要应答
    [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
}

- (void)writePeripheralWithResponse:(CBPeripheral *)p forService:(CBUUID *)sUUID characteristicUUID:(CBUUID *)cUUID withData:(NSData *)data {
    CBService *service = [self searchPeripheral:p serviceWithUUID:sUUID];
    if (!service) {
        return;
    }
    
    CBCharacteristic *characteristic = [self searchCharacteristicWithUUID:cUUID inService:service];
    if (!characteristic) {
        return;
    }
    //发送需要应答
    [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
}

#pragma mark - EEGSmart

+ (CBUUID *)EEGSmartServiceUUID {
    return [CBUUID UUIDWithString:@EGSBL_SERVICE_UUID];
}


+ (CBUUID *)EEGSmartCharacteristicNotifyUUID {
    return [CBUUID UUIDWithString:@EGSBL_CHAR_N_UUID];
}

+ (NSArray<CBUUID *> *)allSupportedServiceUUIDs {
    return @[[CBUUID UUIDWithString:@EGSBL_SERVICE_UUID],
             [CBUUID UUIDWithString:@EGSBL_SERVICE_UUID_Neurosky],
             ];
}

+ (NSArray<CBUUID *> *)allSupportedCharacteristicNotifyUUIDs {
    return @[[CBUUID UUIDWithString:@EGSBL_CHAR_N_UUID],
             [CBUUID UUIDWithString:@EGSBL_CHAR_X_UUID],
             ];
}

+ (NSArray<NSString *> *)allSupportedCharacteristicNotifyUUIDStrings {
    return @[@EGSBL_CHAR_N_UUID, @EGSBL_CHAR_X_UUID];
}

+ (NSArray<CBUUID *> *)allSupportedCharacteristicWirteUUIDs {
    return @[[CBUUID UUIDWithString:@EGSBL_CHAR_W_UUID],
             [CBUUID UUIDWithString:@EGSBL_CHAR_X_UUID]];
}

#pragma mark - Private
- (BOOL)peripheralInConnected:(CBPeripheral *)peripheral {
    for (CBPeripheral *mPeripheral in self.connectedPeripherals) {
        if ([mPeripheral isEqual:peripheral]
             || [mPeripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
            return YES;
        }
    }
    return NO;
}

- (void)scanTimeout:(NSTimer *)timer {
    [_centraManager stopScan];
    if(_delegate && [_delegate respondsToSelector:@selector(bleDidStopScan)]) {
        [_delegate bleDidStopScan];
    }
}


- (CBService *)searchPeripheral:(CBPeripheral *)p serviceWithUUID:(CBUUID *)UUID {
    for (CBService *service in p.services) {
        if ([service.UUID.UUIDString isEqualToString:UUID.UUIDString]) {
            return service;
        }
    }
    
    return nil; //Service not found on this peripheral
}

- (CBCharacteristic *)searchCharacteristicWithUUID:(CBUUID *)UUID inService:(CBService*)service {
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID.UUIDString isEqualToString:UUID.UUIDString]) {
            return characteristic;
        }
    }
    
    return nil; //Characteristic not found on this service
}

- (void)discoverAllCharacteristicsForPeripheral:(CBPeripheral *)p {
    for (int i=0; i < p.services.count; i++) {
        CBService *s = [p.services objectAtIndex:i];
        [p discoverCharacteristics:nil forService:s];
    }
}

#pragma mark - CBCentralManagerDelegate


/**
 *  手机蓝牙状态更新回调
 *
 *  @param central 手机蓝牙管理类
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state != CBManagerStatePoweredOn) {
        [self cancelPeripheralConnection:nil];
        
        [self.connectedPeripherals removeAllObjects];
        [_peripherals removeAllObjects];
    }
    
    if ([_delegate respondsToSelector:@selector(bleCentralManagerDidUpdateState:)]) {
        [_delegate bleCentralManagerDidUpdateState:(CBManagerState)central.state];
    }
}

/**
 *  扫描到从属设备（脑电蓝牙）的回调
 *
 *  @param central           手机蓝牙管理类
 *  @param peripheral        从属设备（脑电蓝牙）
 *  @param advertisementData 从属设备广播数据
 *  @param RSSI              从属设备信号大小
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    NSObject *value = [advertisementData objectForKey:@"kCBAdvDataServiceData"];
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dic = (NSDictionary *)value;
        if ([dic objectForKey:[CBUUID UUIDWithString:@"FFF5"]]) {
            NSString *str =[[NSString alloc] initWithData:[dic objectForKey:[CBUUID UUIDWithString:@"FFF5"]] encoding:NSASCIIStringEncoding];
            peripheral.snCode = str;
        }
        
        if ([dic objectForKey:[CBUUID UUIDWithString:@"180F"]]) {
            NSData *data = [dic objectForKey:[CBUUID UUIDWithString:@"180F"]];
            u_int8_t c;
            [data getBytes:&c range:NSMakeRange(0, 1)];
            peripheral.batVal = @(c);
        }
    }
            
        

    if (!self.peripherals) {
        self.peripherals = [[NSMutableArray alloc] initWithObjects:peripheral, nil];
    } else {
        for(int i = 0; i < self.peripherals.count; i++) {
            CBPeripheral *p = [self.peripherals objectAtIndex:i];
            
            if ((p.identifier == NULL) || (peripheral.identifier == NULL))
                continue;
            
            if ([p.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
                [self.peripherals replaceObjectAtIndex:i withObject:peripheral];
                break;
            }
        }
        
        if (![self.peripherals containsObject:peripheral]) {
            [self.peripherals addObject:peripheral];
        }
    }
    
    if ([_delegate respondsToSelector:@selector(bleDidDiscoverPeripheral:advertisementData:RSSI:)]) {
        [_delegate bleDidDiscoverPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    if (!self.connectedPeripherals.count) {
        [self.connectedPeripherals addObject:peripheral];
    } else {
        if (![self peripheralInConnected:peripheral]) {
            [self.connectedPeripherals addObject:peripheral];
        }
    }
    [peripheral discoverServices:nil];
    peripheral.delegate = self;
    
    _connecting = NO;
    _connectingPeripheral = nil;
    
    if ([_delegate respondsToSelector:@selector(bleDidConnectPeripheral:)]) {
        [_delegate bleDidConnectPeripheral:peripheral];
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [self cancelPeripheralConnection:peripheral];
    _connecting = NO;
    _connectingPeripheral = nil;
    
    if ([_delegate respondsToSelector:@selector(bleDidFailToConnectPeripheral:error:)]) {
        [_delegate bleDidFailToConnectPeripheral:peripheral error:error];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [self disconnectPeripheral:peripheral];
    
    if ([_delegate respondsToSelector:@selector(bleDidDisconnectPeripheral:withError:)]) {
        [_delegate bleDidDisconnectPeripheral:peripheral withError:error];
    }
}

#pragma mark - CBPeripheralDelegate

/**
 *  扫描从属设备服务的回调
 *
 *  @param peripheral 从属设备
 *  @param error      出错返回
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (!error) {
        [self discoverAllCharacteristicsForPeripheral:peripheral];
        
        if ([_delegate respondsToSelector:@selector(bleDidDiscoverServicesForPeripheral:)]) {
            [_delegate bleDidDiscoverServicesForPeripheral:peripheral];
        }
    }
}

/**
 *  扫描从属设备服务中的特征
 *
 *  @param peripheral 从属设备
 *  @param service    服务
 *  @param error      出错返回
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (!error) {
        if ([_delegate respondsToSelector:@selector(bleDidDiscoverPeripheral:characteristicsforService:)]) {
            [_delegate bleDidDiscoverPeripheral:peripheral characteristicsforService:service];
        }
    
        NSArray *UUIDStrings = [EGSBLEManager allSupportedCharacteristicNotifyUUIDStrings];
        for (CBCharacteristic *characteristic in service.characteristics) {
            for (NSString *UUIDString in UUIDStrings) {
                if ([characteristic.UUID.UUIDString isEqualToString:UUIDString]) {
                    [self notifyPeripheral:peripheral
                                        on:YES
                                forService:service.UUID
                        characteristicUUID:characteristic.UUID];
                    break;
                }
            }
        }
    }
}

/**
 *  从属设备的特征状态更新回调
 *
 *  @param peripheral     从属设备
 *  @param characteristic 特征
 *  @param error          出错返回
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
}

/**
 *  从属设备的特征值返回回调，在此获取特征值更新的数据
 *
 *  @param peripheral     从属设备
 *  @param characteristic 特征
 *  @param error          出错返回
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (!error) {
        if ([_delegate respondsToSelector:@selector(bleDidUpdatePeripheral:valueForCharacteristic:)]) {
            [_delegate bleDidUpdatePeripheral:peripheral valueForCharacteristic:characteristic];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if ([_delegate respondsToSelector:@selector(bleDidWritePeripheral:valueForCharacteristic:error:)]) {
        [_delegate bleDidWritePeripheral:peripheral valueForCharacteristic:characteristic error:error];
    }
}

- (void)peripheralIsReadyToSendWriteWithoutResponse:(CBPeripheral *)peripheral {
    
    if ([_delegate respondsToSelector:@selector(blePeripheralIsReadyToSendWriteWithoutResponse:)]) {
        [_delegate blePeripheralIsReadyToSendWriteWithoutResponse:peripheral];
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error  {
    if ([_delegate respondsToSelector:@selector(bleDidUpdatePeripheral:RSSI:)]) {
        [_delegate bleDidUpdatePeripheral:peripheral RSSI:RSSI];
    }
}

- (NSString *)convertDataToMacHexStr:(NSData*)data{
    if (!data || [data length] == 0) {
        return @"";
    }
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%02x", (dataBytes[i]) & 0xff];
            if (string.length) {
                [string appendString:@":"];
                [string appendString:hexStr];
            } else {
                [string appendString:hexStr];
            }
        }
    }];
    
    return string;
}

@end
