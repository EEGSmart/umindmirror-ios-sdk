//
//  EGSLineView.h
//  UMindMirrorSDK
//
//  Created by YRui on 2023/7/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface EGSLineView : UIView

@property (nonatomic, strong) NSMutableArray *datas;

@property (nonatomic, strong) UIColor *lineColor;

@property (nonatomic, assign) NSInteger lineCount;

@property (nonatomic, assign) CGFloat maxValue;

@property (nonatomic, assign) CGFloat minValue;

@property (nonatomic, assign) CGFloat maxValueCount;  //最多显示的点数

@property (nonatomic, assign) CGFloat multiple;


//- (void)addDataToArr:(NSInteger )heartValue;

- (void)addDataToArr:(id )value;

@end

NS_ASSUME_NONNULL_END
