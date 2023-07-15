//
//  EGSControlOrder.h
//  EGSSDK
//
//  Created by mopellet on 2017/8/2.
//  Copyright © 2017年 EEGSmart. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EGSmartDataParser.h"
@interface EGSControlOrder : NSObject

+ (NSData *)controlOrder:(ControlType)type :(SWITCH_TYPE)switchType;
//正常数据开关类别
+ (NSData *)openControlOrder:(ControlType)type;
+ (NSData *)closeControlOrder:(ControlType)type;


@end
