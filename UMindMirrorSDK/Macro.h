//
//  Macro.h
//  UMindMirrorSDK
//
//  Created by YRui on 2023/7/15.
//

#ifndef Macro_h
#define Macro_h


//弱引用/强引用
#define EGSWeakSelf(type) __weak typeof(type) weak##type = type;
#define EGSStrongSelf(type) __strong typeof(type) type = weak##type;

#define UIColorHex(s) [UIColor colorWithRed:(((s & 0xFF0000) >> 16))/255.0 green:(((s &0xFF00) >>8))/255.0 blue:((s &0xFF))/255.0 alpha:1.0]

#endif /* Macro_h */
