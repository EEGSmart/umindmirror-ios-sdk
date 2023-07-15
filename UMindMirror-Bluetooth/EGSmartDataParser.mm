//
//  EGSmartDataParser.m
//  EEGSmartSDK
//
//  Created by 成传友 on 16/5/10.
//  Copyright © 2016年 EEGSmart. All rights reserved.
//

#import "EGSmartDataParser.h"

typedef NS_ENUM(NSUInteger, EGSDataIdentifier) {
    EGSDataIdentifierSYNC       = 0xAA,
    EGSDataIdentifierSIGN       = 0x02,
};

typedef NS_ENUM(NSUInteger, ClassType){
    CLASS_TYPE_CONTROL_SWITCH  = 0x22, // 控制开关
    CLASS_TYPE_CONTROL_DATA    = 0x23, // 控制返回数据
};


@interface BufferStructure : NSObject
@property (nonatomic, assign) ClassType classType;
@property (nonatomic, assign) int head;
@property (nonatomic, assign) int lenth;
@property (nonatomic, strong) NSData *data;
@end

@implementation BufferStructure

@end

@interface EGSmartDataParser () {
    NSMutableDictionary<NSString *, NSMutableData *> *_buffers;
    NSMutableArray *_rawDataArray;
}

@end

@implementation EGSmartDataParser

NSString const * kSwithControlType = @"controlType";
NSString const * kSwithControlValue = @"value";

- (instancetype)init {
    if (self = [super init]) {
        _buffers = [NSMutableDictionary dictionary];
        _rawDataArray = [NSMutableArray new];
    }
    return self;
}


#pragma mark  Public
#pragma mark - sync for android by mopellet start

static int MIN_PACKAGE_UNIT_LENGTH = 8;

- (void)parseData:(NSData *)data forIdentifier:(NSString *)identifier {
    if (!identifier || identifier.length == 0) {
        return;
    }
    
    NSMutableData *bleBuffer = [_buffers objectForKey:identifier];
    if (!bleBuffer) {
        bleBuffer = [NSMutableData data];
        [_buffers setObject:bleBuffer forKey:identifier];
    }
    
    [bleBuffer appendData:data];
    
    for (int i = 0; i < bleBuffer.length && bleBuffer.length >= MIN_PACKAGE_UNIT_LENGTH; i++) {
        u_int8_t first = 0;
        [bleBuffer getBytes:&first range:NSMakeRange(0, 1)];
        u_int8_t second = 0;
        [bleBuffer getBytes:&second range:NSMakeRange(1, 1)];
        //新增2字节时间
        u_int8_t timeFirst = 0;
        [bleBuffer getBytes:&timeFirst range:NSMakeRange(2, 1)];
        u_int8_t timeSecond = 0;
        [bleBuffer getBytes:&timeSecond range:NSMakeRange(3, 1)];
        
        if (EGSDataIdentifierSYNC == first && EGSDataIdentifierSYNC == second) {
            //若果蓝牙数据包加《序号》的话此处解析顺延Plan位一位例将(2,1)顺延到(3,1)
            u_int8_t count = 0;//取PLEN值,包内Data长度
            [bleBuffer getBytes:&count range:NSMakeRange(4, 1)];
            
            int packLen = (count & 0xff) + 6; //计算一包长度 0xaa 0xaa time(2) PLEN(1) CheckSum(1) 共6个长度
            if (packLen <= bleBuffer.length) {
                NSMutableData *onePackData = [NSMutableData data];
                for (int j = 0; j < packLen; j++) {
                    u_int8_t c = 0;
                    [bleBuffer getBytes:&c range:NSMakeRange(0, 1)];
                    [bleBuffer replaceBytesInRange:NSMakeRange(0, 1) withBytes:NULL length:0];
                    [onePackData appendBytes:&c length:1];
                }
                
                if ([self checkSum:onePackData]) {
                    [self startParseBuffer:onePackData forIdentifier:identifier];
                    //NSLog(@"校验成功:%@",onePackData);
                } else {
                    NSLog(@"校验不成功：%@" ,onePackData);
                }
                
            } else {
                break;
            }
        } else {
            [bleBuffer replaceBytesInRange:NSMakeRange(0, 1) withBytes:NULL length:0];
        }
    }
}

- (void)startParseBuffer:(NSData *)buffer forIdentifier:(NSString *)identifier {
    if (buffer.length < 7) return;
    u_int8_t c = 0;
    [buffer getBytes:&c range:NSMakeRange(5, 1)];
    ClassType classType = (ClassType)(0xff & c);
    NSArray <BufferStructure *> *bufferStructures = [NSArray arrayWithArray:[self dataSeparation:classType :buffer]];
    
    for (BufferStructure *bu in bufferStructures) {
        ClassType type = bu.classType;
        switch (type) {
            case CLASS_TYPE_CONTROL_SWITCH:
                [self parseControlSwitch:bu forIdentifier:identifier];
                break;
            case CLASS_TYPE_CONTROL_DATA:
                [self parseControlData:bu forIdentifier:identifier];
                break;
            default:
                break;
        }
    }
}

//* 把一条完整的buff分解成一组一组的数据，每组数据都带classType
- (NSArray <BufferStructure *> *)dataSeparation:(ClassType)classType :(NSData *)buffer {
    NSData *valueBuffer = [NSData dataWithData:buffer];
    NSMutableArray *list = [[NSMutableArray alloc] init];
    for (int i = 6; i < valueBuffer.length - 1;) {
        u_int8_t cHead = 0;
        [valueBuffer getBytes:&cHead range:NSMakeRange(i, 1)];
        i++;
        int head = cHead & 0xff; //head，代表是什么数据
        
        u_int8_t cLen = 0;
        [valueBuffer getBytes:&cLen range:NSMakeRange(i, 1)];
        i++;
        int len = cLen & 0xff ; //获取数据长度len
        if ((i + len) > valueBuffer.length) {
            NSLog(@"此处崩溃：%@   len:%d  bufferlen:%ld",valueBuffer,len,(unsigned long)valueBuffer.length);
            continue;
        }
        NSData *data = [valueBuffer subdataWithRange:NSMakeRange(i, len)];
        i += len;
        BufferStructure *buff = [[BufferStructure alloc] init];
        buff.classType = classType;
        buff.head = head;
        buff.lenth = len;
        buff.data = data;
        
        [list addObject:buff];
    }
    
    return list;
}


#pragma mark - 解析控制开关
- (void)parseControlSwitch:(BufferStructure *)bu forIdentifier:(NSString *)identifier {
    if (!bu.data) {
        return;
    }
    ControlType type = (ControlType)bu.head;
    NSData *data = [NSData dataWithData:bu.data];
    
    u_int8_t c = 0;
    [data getBytes:&c range:NSMakeRange(data.length - 1, 1)];
    
    if (c == 0x01) {
        u_int8_t code = 0;
        [data getBytes:&code range:NSMakeRange(0, 1)];
        
        int switchCode = code & 0xff;
        
        NSDictionary *dictionary = @{kSwithControlType:@(type),
                                     kSwithControlValue:@(switchCode)};
        if (_delegate && [_delegate respondsToSelector:@selector(didAnalyseControlSwitch:forIdentifier:)]) {
            [_delegate didAnalyseControlSwitch:dictionary forIdentifier:identifier];
        }
    }
}

#pragma mark - 解析控制数据
- (void)parseControlData:(BufferStructure *)bu forIdentifier:(NSString *)identifier {
    if (!bu.data || bu == nil || bu.data == nil) {
        return;
    }
    
    ControlType type = (ControlType)bu.head;
    NSData *dataValue = [NSData dataWithData:bu.data];
    u_int8_t c = 0 ;
    // 最终解析
    switch (type) {
        case CONTROL_TYPE_POOR_SIGNAL_QUALITY:
        {
            if (!dataValue.length) {
                return;
            }
            [dataValue getBytes:&c range:NSMakeRange(0, 1)];
            int mPoorQuality = 0xff & c;
            if ([_delegate respondsToSelector:@selector(didGetSignalQuality:forIdentifier:)]) {
                [_delegate didGetSignalQuality:mPoorQuality forIdentifier:identifier];
            }
        }
            break;
        case CONTROL_TYPE_EEG_DATA: {
            if (!dataValue.length || (dataValue.length % 2 != 0)) {
                return;
            }
            
            NSArray *convertedRawData = [NSArray arrayWithArray:[self convertRawData:dataValue]];
            NSMutableArray *afterArray = [[NSMutableArray alloc] init];
            for (NSNumber *number in convertedRawData) {
                NSInteger raw  =  [number integerValue] - 0x2000;
                [afterArray addObject:@(raw)];
            }
            if ([_delegate respondsToSelector:@selector(didGetRawDatas:forIdentifier:)]) {
                [_delegate didGetRawDatas:[NSArray arrayWithArray:afterArray] forIdentifier:identifier];
            }
        }
            break;
        case CONTROL_TYPE_GYRO_ALGO: { //陀螺仪算法打开,陀螺仪按一个byte去解析
            if (dataValue.length == 2) {
                [dataValue getBytes:&c range:NSMakeRange(0, 1)];
                int bodyPosi = 0xff & c;
                [dataValue getBytes:&c range:NSMakeRange(1, 1)];
                int bodyMoveDegree = 0xff & c;
                
                if (_delegate && [_delegate respondsToSelector:@selector(didAnalyseBodyPosition:bodyMovelLevel:forIdentifier:)]) {
                    [_delegate didAnalyseBodyPosition:bodyPosi bodyMovelLevel:bodyMoveDegree forIdentifier:identifier];
                }
            }
        }
            break;
        case CONTROL_TYPE_UPDATE_TIME: {
            if (_delegate && [_delegate respondsToSelector:@selector(didAnalyseUpdateTimeForIdentifier:)]) {
                [_delegate didAnalyseUpdateTimeForIdentifier:identifier];
            }
        }
            break;
        case CONTROL_TYPE_INQUIRE_DEVICE_HARDWARE: {
            if (!dataValue.length) {
                return;
            }
            //硬件版本
            NSString *hardware = [[NSString alloc]initWithData:dataValue encoding:NSASCIIStringEncoding];
            if(_delegate && [_delegate respondsToSelector:@selector(didGetHardWareVersion:forIdentifier:)]) {
                [_delegate didGetHardWareVersion:hardware forIdentifier:identifier];
            }
        }
            break;
        case CONTROL_TYPE_INQUIRE_DEVICE_SOFTWARE: {
            if (!dataValue.length) {
                return;
            }
            //软件版本
            NSString *software = [[NSString alloc]initWithData:dataValue encoding:NSASCIIStringEncoding];
            if(_delegate && [_delegate respondsToSelector:@selector(didGetSoftWareVersion:forIdentifier:)]) {
                [_delegate didGetSoftWareVersion:software forIdentifier:identifier];
            }
        }
            break;
        case CONTROL_TYPE_INQUIRE_DEVICE_SN: {
            //序列号
            if (!dataValue.length) {
                return;
            }
            
            NSString *snCode = [[NSString alloc]initWithData:dataValue encoding:NSASCIIStringEncoding];
            //            NSLog(@"snCode = %@",snCode);
            if(_delegate && [_delegate respondsToSelector:@selector(didGetSNVersion:forIdentifier:)]) {
                [_delegate didGetSNVersion:snCode forIdentifier:identifier];
            }
            
        }
            break;
            
        case CONTROL_TYPE_BATCH_CONTROL: {
            NSLog(@"组合开关指令222 初始化成功");
        }
            break;
        case CONTROL_TYPE_POWER_OFF:  {
            if (dataValue.length == 1 || dataValue.length == 2) {
                [dataValue getBytes:&c range:NSMakeRange(0, 1)];
                NSInteger type = 0xff & c;
                
                if (_delegate && [_delegate respondsToSelector:@selector(didGetPowerOffCommandType:forIdentifier:)]) {
                    [_delegate didGetPowerOffCommandType:type forIdentifier:identifier];
                }
            }
        }
            break;
        case CONTROL_TYPE_BATTERY_SUP_DATA: {
            //[0]：充电状态 0：未充电 1：充电中 2：充电完成
            //[1]：电池电量，单位%
            //[2:3]：电池电压，单位mv，小端模式。
            NSData *valueData = [NSData dataWithData:dataValue];
            NSMutableArray *rawData = [NSMutableArray new];
            // 解充电状态和电池电量数据，按1位转换数据
            for (int i = 0; i < 2; i +=1) {
                u_int8_t c;
                [valueData getBytes:&c range:NSMakeRange(i, 1)];
                int raw = (0xff & c);
                [rawData addObject:@(raw)];
            }
            
            // 解电压数据，小端模式(低位在前，高位在后)，按2位转换数据
            for (NSUInteger i = valueData.length - 2; i < valueData.length; i += 2) {
                u_int8_t c;
                [valueData getBytes:&c range:NSMakeRange(i, 1)];
                uint8_t s;
                [valueData getBytes:&s range:NSMakeRange(i+1, 1)];
                int raw = (0xff & c) | (0xff & s) << 8;
                [rawData addObject:@(raw)];
            }
            
            if ([_delegate respondsToSelector:@selector(didAnalyseBattery:chargeState:forIdentifier:)]) {
                if (rawData.count > 1) {
                    NSInteger chargeState = ((NSNumber *)rawData[0]).integerValue;
                    NSInteger batVal = ((NSNumber *)rawData[1]).integerValue; //电池电量，百分比
                    [_delegate didAnalyseBattery:batVal chargeState:chargeState forIdentifier:identifier];
                }
            }
        }
            break;
        default:
            break;
    }
}

- (void)removeBufferForIdentifier:(nullable NSString *)identifier {
    if (!identifier || identifier.length) {
        NSArray *allKeys = _buffers.allKeys;
        for (NSString *key in allKeys) {
            [self _removeBufferForKey:key];
        }
    } else {
        [self _removeBufferForKey:identifier];
    }
    
    [_rawDataArray removeAllObjects];
}

- (void)_removeBufferForKey:(NSString *)key {
    NSMutableData *bleBuffer = [_buffers objectForKey:key];
    [bleBuffer setLength:0];
    [_buffers removeObjectForKey:key];
}


- (BOOL)checkSum:(NSData *)buffer {
    int sum = 0;
    u_int8_t c = 0;
    [buffer getBytes:&c range:NSMakeRange(4, 1)];
    int dataLength = 0xff & (int)c; // Data length //取PLEN值,包内Data长度
    int checkSumIndex = dataLength + 5;      // Checksum index
    
    //计算包内data总长度，从 Plen（head2 time2 plen1) 后一位开始统计
    for (int i = 5; i < checkSumIndex; i++) {
        u_int8_t t;
        [buffer getBytes:&t range:NSMakeRange(i, 1)];
        int j = (int) t & 0xff;
        sum += j;
    }
    sum &= 0xff;
    sum ^= 0xff;
    u_int8_t k;
    [buffer getBytes:&k range:NSMakeRange(checkSumIndex, 1)];
    int checkSum = (0xff & k);//取cheksum值
    return sum == checkSum;
}

- (NSArray <NSNumber *>*)convertRawData:(NSData *)inputata {
    NSData *valueData = [NSData dataWithData:inputata];
    NSMutableArray * rawData = [[NSMutableArray alloc] init];
    for (int i = 0; i<valueData.length; i +=2) {
        u_int8_t c;
        [valueData getBytes:&c range:NSMakeRange(i, 1)];
        uint8_t s;
        [valueData getBytes:&s range:NSMakeRange(i+1, 1)];
        int16_t raw = (0xff & c) | (0xff & s) << 8;
        [rawData addObject:@(raw)];
    }
    return [NSArray arrayWithArray:rawData];
}


@end
