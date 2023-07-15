//
//  EGSAlertView.m
//  UMindMirrorSDK
//
//  Created by YRui on 2023/7/15.
//

#import "EGSAlertView.h"
#import <Masonry/Masonry.h>
#import "Macro.h"
#import "UIView+Helpers.h"
#import <BlocksKit+UIKit.h>

@interface EGSAlertView () {
    NSMutableArray *_otherButtons;
    NSMutableArray *_cancelButtons;
}

@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIView *footView;

@property(nonatomic, copy)NSString *title;
@property(nonatomic, copy)NSString *message;

@property(nonatomic, copy)NSString *cancelButtonTitle;

@property(nonatomic, strong)NSMutableArray *buttons;


@end

@implementation EGSAlertView

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString * _Nullable)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...{
    if (self = [super initWithFrame:[[UIScreen mainScreen] bounds]]) {
        
        self.title = title;
        self.message = message;
        self.cancelButtonTitle = cancelButtonTitle;
        
        _textAlignment = NSTextAlignmentCenter;
        _cancelButtonFont = [UIFont systemFontOfSize:17];
        _cancelButtonTitleColor = UIColor.blackColor;
        _otherButtonFont = [UIFont systemFontOfSize:17];
        _otherButtonTitleColor = UIColor.blackColor;
        [[[UIApplication sharedApplication] keyWindow] addSubview:self];
        
        [self addSubview:self.maskView];
        [self addSubview:self.contentView];
        
        NSMutableArray *buttonTitles = [[NSMutableArray alloc] init];
        
        if (otherButtonTitles) {
            NSString *str;
            va_list args;
            NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:1];
            [array addObject:otherButtonTitles];
            va_start(args, otherButtonTitles);
            while ((str = va_arg(args, NSString *))) {
                if (str) {
                    [array addObject:str];
                }
            }
            va_end(args);
            
            for (NSString *titles in array) {
                [buttonTitles addObject:titles];
            }
        }
        
        if (self.cancelButtonTitle) {
            //当按钮数>3时，取消按钮放最下方 否则取消按钮在左边
            if (buttonTitles.count > 1) {
                [buttonTitles addObject:cancelButtonTitle];
            } else {
                [buttonTitles insertObject:cancelButtonTitle atIndex:0];
            }
            
        }
        
        self.buttons = buttonTitles;
    }
    return self;
}

- (void)setCancelButtonFont:(UIFont *)cancelButtonFont {
    if (!cancelButtonFont) {
        return;
    }
    _cancelButtonFont = cancelButtonFont;
    for (UIButton *button in _cancelButtons) {
        button.titleLabel.font = cancelButtonFont;
    }
}

- (void)setCancelButtonTitleColor:(UIColor *)cancelButtonTitleColor {
    if (!cancelButtonTitleColor) {
        return;
    }
    _cancelButtonTitleColor = cancelButtonTitleColor;
    for (UIButton *button in _cancelButtons) {
        [button setTitleColor:cancelButtonTitleColor forState:UIControlStateNormal];
    }
}

- (void)setOtherButtonFont:(UIFont *)otherButtonFont {
    if (!otherButtonFont) {
        return;
    }
    _otherButtonFont = otherButtonFont;
    for (UIButton *button in _otherButtons) {
        button.titleLabel.font = otherButtonFont;
    }
}

- (void)setOtherButtonTitleColor:(UIColor *)otherButtonTitleColor {
    if (!otherButtonTitleColor) {
        return;
    }
    _cancelButtonTitleColor = otherButtonTitleColor;
    for (UIButton *button in _otherButtons) {
        [button setTitleColor:otherButtonTitleColor forState:UIControlStateNormal];
    }
}


- (UIView *)maskView {
    if (!_maskView) {
        _maskView = [[UIView alloc] initWithFrame:CGRectZero];
        _maskView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    }
    return _maskView;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:CGRectZero];
        _contentView.backgroundColor = [UIColor whiteColor];
        _contentView.layer.cornerRadius = 13;
        _contentView.clipsToBounds = YES;
        [_contentView addSubview:self.titleLabel];
        [_contentView addSubview:self.messageLabel];
        [_contentView addSubview:self.footView];
    }
    return _contentView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont systemFontOfSize:18];
        _titleLabel.textColor = UIColor.blackColor;
        _titleLabel.text = self.title;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        [_titleLabel sizeToFit];
    }
    
    return _titleLabel;
}

- (UILabel *)messageLabel {
    if (!_messageLabel) {
        _messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _messageLabel.font = [UIFont systemFontOfSize:14];
        _messageLabel.textColor = UIColor.blackColor;
        _messageLabel.text = self.message;
        _messageLabel.textAlignment = self.textAlignment;
        _messageLabel.numberOfLines = 0;
        
        [_messageLabel sizeToFit];
    }
    
    return _messageLabel;
}

- (UIView *)footView {
    if (!_footView) {
        _footView = [[UIView alloc] initWithFrame:CGRectZero];
    }
    
    return _footView;
}


- (void)setButtons:(NSMutableArray *)buttons {
    _cancelButtons = [[NSMutableArray alloc] init];
    _otherButtons = [[NSMutableArray alloc] init];
    
    _buttons = buttons;
    
    for (id button in self.footView.subviews) {
        [button removeFromSuperview];
    }
    
    //顶部线条
    if (buttons.count) {
        UIView *lineView = [UIView new];
        [_footView addSubview:lineView];
        lineView.backgroundColor = UIColorHex(0xE6E6E6);
        [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.mas_equalTo(self->_footView);
            make.height.mas_equalTo(0.5);
        }];
    }
    
    EGSWeakSelf(self)
    if (buttons.count == 1) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectZero];
        [button setTitle:buttons[0] forState:UIControlStateNormal];
        
        if (self.cancelButtonTitle) {
            [button setTitleColor:_cancelButtonTitleColor forState:UIControlStateNormal];
            button.titleLabel.font = _cancelButtonFont;
            [_cancelButtons addObject:button];
        } else {
            [button setTitleColor:_otherButtonTitleColor forState:UIControlStateNormal];
            button.titleLabel.font = _otherButtonFont;
            [_otherButtons addObject:button];
        }
        
        [button bk_addEventHandler:^(id sender) {
            EGSStrongSelf(self)
            if (!self.isModal) {
                [self dismiss];
            }
            
            if (self.alerViewClickBlock) {
                self.alerViewClickBlock(self, 0);
            }
            
        } forControlEvents:UIControlEventTouchUpInside];
        
        [self.footView addSubview:button];
        self.footView.height = button.maxY;
    } else if (buttons.count == 2) {
        
        for (NSInteger i = 0; i < buttons.count; i++) {
            CGFloat width = _footView.width / 2;
            CGFloat originX = i * width;
            UIButton *button = [[UIButton alloc] initWithFrame:CGRectZero];
            [self.footView addSubview:button];
            [button setTitle:buttons[i] forState:UIControlStateNormal];
            button.tag = i + 1000;
            
            if (i == 0) {
                if (self.cancelButtonTitle) {
                    [button setTitleColor:_cancelButtonTitleColor forState:UIControlStateNormal];
                    button.titleLabel.font = _cancelButtonFont;
                    [_cancelButtons addObject:button];
                } else {
                    [button setTitleColor:_otherButtonTitleColor forState:UIControlStateNormal];
                    button.titleLabel.font = _otherButtonFont;
                    [_otherButtons addObject:button];
                }
            } else  {
                [button setTitleColor:_otherButtonTitleColor forState:UIControlStateNormal];
                button.titleLabel.font = _otherButtonFont;
                [_otherButtons addObject:button];
            }
            
            UIView *lineView = [[UIView alloc] initWithFrame:CGRectZero];
            [button addSubview:lineView];
            lineView.backgroundColor = UIColorHex(0xE6E6E6);
            [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.height.mas_equalTo(button);
                make.width.mas_equalTo(0.5);
            }];
            
            
            [button bk_addEventHandler:^(id sender) {
                EGSStrongSelf(self)
                UIButton *btn = (UIButton *)sender;
                if (!self.isModal) {
                    [self dismiss];
                }
                if (self.alerViewClickBlock) {
                    self.alerViewClickBlock(self, btn.tag - 1000);
                }
            } forControlEvents:UIControlEventTouchUpInside];
        }
        
    } else {
        for (NSInteger i = 0; i < buttons.count; i++) {
            UIButton *button = [[UIButton alloc] initWithFrame:CGRectZero];
            [self.footView addSubview:button];
            [button setTitle:buttons[i] forState:UIControlStateNormal];
            button.tag = i + 1000;
            
            [button setTitleColor:_otherButtonTitleColor forState:UIControlStateNormal];
            button.titleLabel.font = _otherButtonFont;
            
            UIView *lineView = [[UIView alloc] initWithFrame:CGRectZero];
            [button addSubview:lineView];
            lineView.backgroundColor = UIColorHex(0xE6E6E6);
            
            [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.bottom.mas_equalTo(button);
                make.height.mas_equalTo(0.5);
            }];
            
            if (i == buttons.count - 1) {
                if (self.cancelButtonTitle) {
                    [button setTitleColor:_cancelButtonTitleColor forState:UIControlStateNormal];
                    button.titleLabel.font = _cancelButtonFont;
                    [_cancelButtons addObject:button];
                } else {
                    [_otherButtons addObject:button];
                }
            } else {
                [_otherButtons addObject:button];
            }
            
            [button bk_addEventHandler:^(id sender) {
                UIButton *btn = (UIButton *)sender;
                EGSStrongSelf(self)
                if (!self.isModal) {
                    [self dismiss];
                }
                if (self.alerViewClickBlock) {
                    self.alerViewClickBlock(self, btn.tag - 1000);
                }
            } forControlEvents:UIControlEventTouchUpInside];
        }
    }
    [self updateUI];
}


- (void)updateUI {
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.inset = 0;
    }];
    
    [self.maskView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self);
    }];
    
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(20);
        make.left.right.inset(5);
    }];
    
    if (self.title && self.title.length > 0) {
        [self.messageLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(8);
            make.left.mas_greaterThanOrEqualTo(24);
            make.right.mas_lessThanOrEqualTo(self.contentView).offset(-24);
            make.centerX.mas_equalTo(self.contentView);
        }];
    } else {
        [self.messageLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.titleLabel);
            make.left.mas_greaterThanOrEqualTo(self.contentView);
            make.right.mas_lessThanOrEqualTo(self.contentView);
            make.centerX.mas_equalTo(self.contentView);
        }];
    }
    
    
    
    if (self.buttons.count == 1) {
        UIButton *button = _cancelButtons.count > 0 ? [_cancelButtons firstObject] : [_otherButtons firstObject];
        [button mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(0.5);
            make.left.right.bottom.mas_equalTo(self.footView);
            make.height.mas_equalTo(48);
        }];
    } else if (self.buttons.count == 2) {
        UIButton *leftButton = _cancelButtons.count > 0 ? [_cancelButtons firstObject] : [_otherButtons firstObject];
        UIButton *rightButton = _otherButtons.lastObject;
        
        [leftButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(0.5);
            make.left.bottom.mas_equalTo(self.footView);
            make.height.mas_equalTo(48);
        }];
        
        [rightButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(self.footView);
            make.left.mas_equalTo(leftButton.mas_right);
            make.width.height.top.mas_equalTo(leftButton);
        }];
        
    } else if (self.buttons.count > 2) {
        NSMutableArray *allButtons = [[NSMutableArray alloc] initWithArray:_otherButtons];
        [allButtons addObjectsFromArray:_cancelButtons];
        
        
        [allButtons mas_distributeViewsAlongAxis:MASAxisTypeVertical withFixedSpacing:0 leadSpacing:0 tailSpacing:0];
        
        [allButtons mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(48);
            make.width.mas_equalTo(self.footView);
        }];
    }
    
    
    [self.footView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.messageLabel.mas_bottom).offset(26);
        make.left.right.mas_equalTo(self.contentView);
    }];
    
    [self.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(280);
        make.center.mas_equalTo(self);
        make.bottom.mas_equalTo(self.footView);
    }];
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    _textAlignment = textAlignment;
    self.messageLabel.textAlignment = textAlignment;
}


- (void)show {
    [self.contentView centerAlignForSuperview];
    self.contentView.layer.opacity = 0.5f;
    self.contentView.layer.transform = CATransform3DMakeScale(1.3f, 1.3f, 1.0);
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.contentView.layer.opacity = 1.0f;
        self.contentView.layer.transform = CATransform3DMakeScale(1, 1, 1);
    } completion:NULL];
}

- (void)dismiss {
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}


@end

