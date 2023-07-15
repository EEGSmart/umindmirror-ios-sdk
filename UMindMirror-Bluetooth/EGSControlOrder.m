//
//  EGSControlOrder.m
//  EGSSDK
//
//  Created by mopellet on 2017/8/2.
//  Copyright © 2017年 EEGSmart. All rights reserved.
//

#import "EGSControlOrder.h"

@implementation EGSControlOrder

+ (NSData *)controlOrder:(ControlType)type :(SWITCH_TYPE)switchType {
    //aaaa 0000 0522 05020001 d5
    
    int CONTROL_SWITCH = 0x22;//控制开关类别
    NSMutableArray *array = [NSMutableArray array];
    
    [array insertObject:@(0x00) atIndex:0];
    [array insertObject:@(switchType) atIndex:0];
    [array insertObject:@(array.count) atIndex:0];
    [array insertObject:@(type) atIndex:0];
    [array insertObject:@(CONTROL_SWITCH) atIndex:0];
    [array insertObject:@(array.count) atIndex:0];
    
    
    int checkSum = 0;
    if (array.count > 0) {
        for (int i = 1; i < array.count; i++) {
            checkSum = checkSum + [[array objectAtIndex:i] intValue];
        }
    }
    NSMutableData *order = [[NSMutableData alloc] init];
    int ORDER_HEADER = 0xaa;
    [order appendBytes:&ORDER_HEADER length:1];
    [order appendBytes:&ORDER_HEADER length:1];
    int ORDER_TIME = 0x00;//时间,2字节
    [order appendBytes:&ORDER_TIME length:1];
    [order appendBytes:&ORDER_TIME length:1];
    
    for(int i = 0; i < array.count; i++){
        int temp = [[array objectAtIndex:i] intValue];
        [order appendBytes:&temp length:1];
    }
    
    checkSum = 0xff - (checkSum & 0xff);
    [order appendBytes:&checkSum length:1];
    return order;
}

+ (NSData *)openControlOrder:(ControlType)type {
    return [self controlOrder:type :SWITCH_TYPE_OPEN];
}



+ (NSData *)closeControlOrder:(ControlType)type {
    return [self controlOrder:type :SWITCH_TYPE_CLOSE];
}


@end
