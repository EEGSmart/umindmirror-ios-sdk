//
//  EGSLineView.m
//  UMindMirrorSDK
//
//  Created by YRui on 2023/7/15.
//

#import "EGSLineView.h"
#import "Macro.h"
#import "UIView+Helpers.h"
#import <Masonry/Masonry.h>


@interface EGSLineView ()
@property (nonatomic, strong) UIBezierPath *path;
@property (nonatomic, strong) CAShapeLayer *shapLayer;
@property (nonatomic, assign) CGFloat topSpace;
@property (nonatomic, assign) CGFloat leftSpace;
@property (nonatomic, assign) CGFloat bottomSpace;
@property (nonatomic, assign) CGFloat rightSpace;
@property (nonatomic, assign) CGFloat space;

@end

@implementation EGSLineView




-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        self.clipsToBounds = YES;
        self.lineColor = UIColorHex(0x2EFC08);
        self.space = 2;
        self.maxValue = 200;
        self.minValue = 50;
        self.topSpace = 10;
        self.leftSpace = 30;
        self.bottomSpace = 10;
        self.rightSpace = 0;
        self.maxValueCount = 256 * 3;
        self.multiple = 1.0;
        self.lineCount = 5;
        self.datas = [NSMutableArray array];
    }
    return self;
}


- (void)awakeFromNib {
    [super awakeFromNib];
    self.clipsToBounds = YES;
    self.lineColor = UIColorHex(0x2EFC08);
    self.space = 2;
    self.maxValue = 200;
    self.minValue = 50;
    self.topSpace = 10;
    self.leftSpace = 30;
    self.bottomSpace = 10;
    self.rightSpace = 0;
    self.maxValueCount = 256 * 3;
    self.multiple = 1.0;
    self.lineCount = 5;
    self.datas = [NSMutableArray array];
}


- (void)addDataToArr:(id)value {
    if ([value isKindOfClass:[NSArray class]]) {
        NSArray *dataValue = value;
        
        if (dataValue.count == 0) {
            [self.datas removeAllObjects];
        }
        
        [self.datas addObjectsFromArray:dataValue];
        if (self.datas.count > self.maxValueCount) {
            //将新数据保留，旧数据从数组中删除掉
            [self.datas removeObjectsInRange:NSMakeRange(0, self.datas.count - self.maxValueCount)];
        }
    } else {
        if (self.datas.count >= self.maxValueCount) {
            [self.datas removeLastObject];
        }
        // 数值存储
        [self.datas insertObject:value atIndex:0];
    }
    
    [self.layer addSublayer:self.shapLayer];
    [self drawPoint];
}

- (void)drawPoint {
    [self.path removeAllPoints];
    self.path = nil;
    
    self.space = (CGFloat)(self.width - self.leftSpace - self.rightSpace) / (self.maxValueCount * 1.0f);

    for (int i = 0; i < self.datas.count; i++) {
        CGPoint point;
        point.x = i * self.space + self.leftSpace;
        CGFloat space = (self.height - (self.topSpace + self.bottomSpace)) / ((self.maxValue - self.minValue) * 1.0f);
        point.y = space * (self.maxValue - [self.datas[i] floatValue] * self.multiple) + self.topSpace;
        
        if (i == 0) {
            [self.path moveToPoint:CGPointMake(point.x, point.y)];
        } else {
            [self.path addLineToPoint:CGPointMake(point.x, point.y)];
        }
    }
    
    self.shapLayer.path = self.path.CGPath;
}

- (void)reCreateView{
    if (self.datas.count>0) {
        NSInteger index = self.datas.count;
        CGPoint pp[2];
        [self.datas[index-1] getBytes:&pp[0] length:sizeof(CGPoint)];
        [self.path addLineToPoint:CGPointMake(pp[0].x,pp[0].y)];
        self.shapLayer.path = self.path.CGPath;
    }
}

- (UIBezierPath *)path{
    if (!_path) {
        _path = [UIBezierPath bezierPath];
    }
    return _path;
}

- (CAShapeLayer *)shapLayer{
    if (!_shapLayer) {
        _shapLayer = [CAShapeLayer layer];
        _shapLayer.lineWidth = 1;
        _shapLayer.strokeColor = self.lineColor.CGColor;
        _shapLayer.fillColor =  [UIColor clearColor].CGColor;
        _shapLayer.lineCap =  kCALineCapRound;
        _shapLayer.lineJoin = kCALineJoinRound;
        _shapLayer.contentsScale = [[UIScreen mainScreen] scale];
        self.path = [self path];
    }
    return _shapLayer;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self drawLine];
}

- (void)drawLine {
    CGFloat space = (self.height - (self.topSpace + self.bottomSpace)) / (self.maxValue - self.minValue);
    
    NSInteger vSpace =  (NSInteger)(self.maxValue - self.minValue) / (self.lineCount - 1);
    
    for (int i = 0; i < self.lineCount; i++) {
        UILabel *hLine = [UILabel new];
        hLine.backgroundColor = UIColorHex(0xb2d1f9);
        [self addSubview:hLine];
        
        UILabel *label = [UILabel new];
        [self addSubview:label];
        label.text = [NSString stringWithFormat:@"%.0f", self.minValue + vSpace * i];
        label.font = [UIFont systemFontOfSize:12];
        label.textColor = UIColor.blackColor;
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self);
            make.centerY.mas_equalTo(hLine);
            make.right.mas_equalTo(hLine.mas_left);
        }];
        
        
        [hLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(space * (self.maxValue - self.minValue - vSpace * i) + self.topSpace);
            make.left.mas_equalTo(self.leftSpace);
            make.right.offset(-self.rightSpace);
            make.height.mas_equalTo(0.5);
        }];
    }
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
}

- (void)dealloc{
    [self.shapLayer removeFromSuperlayer];
    self.shapLayer = nil;
}

@end
