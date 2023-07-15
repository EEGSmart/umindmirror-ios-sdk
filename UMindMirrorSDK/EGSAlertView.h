//
//  EGSAlertView.h
//  UMindMirrorSDK
//
//  Created by YRui on 2023/7/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class EGSAlertView;

typedef void(^EGSAlertViewClickBlock)(EGSAlertView *alertView, NSInteger index);

@interface EGSAlertView : UIView


@property(nonatomic, strong)UIFont *cancelButtonFont;
@property(nonatomic, strong)UIColor *cancelButtonTitleColor;

@property(nonatomic, strong)UIFont *otherButtonFont;
@property(nonatomic, strong)UIColor *otherButtonTitleColor;

@property(nonatomic, assign)NSTextAlignment textAlignment;

@property(nonatomic, copy)EGSAlertViewClickBlock alerViewClickBlock;


/// 是否是模态
@property(nonatomic, assign)BOOL isModal;

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString * _Nullable)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

- (void)show;
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
