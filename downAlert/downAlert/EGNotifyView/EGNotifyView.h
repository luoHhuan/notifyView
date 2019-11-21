//
//  EGNotifyView.h
//  downAlert
//
//  Created by Luoh on 2019/11/20.
//  Copyright © 2019 EgooNet. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class EGNotifyViewConfig;

@interface EGNotifyView : UIView
/**
 显示通知
 @param notify 通知文字
 */
+ (EGNotifyView *)showNotify:(NSString *)notify nickName:(NSString *)nickName notifyTime:(NSString *)notifyTime;

+ (EGNotifyView *)showNotify:(NSString *)notify nickName:(NSString *)nickName notifyTime:(NSString *)notifyTime showView:(UIView *)showView;

+ (EGNotifyView *)showNotify:(NSString *)notify nickName:(NSString *)nickName notifyTime:(NSString *)notifyTime showView:(UIView *)showView config:(EGNotifyViewConfig *)config;

@end

/** 背景颜色值的类型, 默认 EGNotifyViewBackgroundColorTypeSuccess */
typedef NS_ENUM(NSInteger, EGNotifyViewBackgroundColorType) {
    EGNotifyViewBackgroundColorTypeSuccess, //成功
    EGNotifyViewBackgroundColorTypeDanger, //错误
    EGNotifyViewBackgroundColorTypeWarning, //警告
    EGNotifyViewBackgroundColorTypeInfo, //信息
};

/** 通知框出现的样式, 默认 JMNotifyViewStyleFit */
typedef NS_ENUM(NSInteger, EGNotifyViewStyle) {
    EGNotifyViewStyleFit, //默认样式 (上 左 右 有间距)
    EGNotifyViewStyleFill, //填满样式 (上 左 右 无间距)
};

typedef void(^RespondToOneTapGesture)(BOOL respondOneTap);

@interface EGNotifyViewConfig : NSObject

/*** 默认初始化方法 ***/
+ (EGNotifyViewConfig *)defaultNotifyConfig;

/***  通知样式 ***/
/** 通知样式 */
@property (nonatomic, assign) EGNotifyViewStyle notifyStyle;

/***  背景颜色 ***/
/**
 通知视图的背景颜色类型
 */
@property (nonatomic, assign) EGNotifyViewBackgroundColorType backgroundColorType;
/**
 通知视图的背景颜色(如果 backgroundType 不适用, 可通过此字段进行自定义)
 */
@property (nonatomic, strong) UIColor *backgroundColor;

/***  字体文字设置 ***/
/**
 文字字体大小 (默认 16)
 */
@property (nonatomic, assign) CGFloat textSize;
/**
 文字字体颜色 (默认 black)
 */
@property (nonatomic, strong) UIColor *textColor;
/**
 文字的行间距 (默认 2.f)
 */
@property (nonatomic, assign) CGFloat textLineSpace;

/***  动画设置 ***/
/**
 通知视图悬停时间 (默认 2.0)
 */
@property (nonatomic, assign) CGFloat notifyViewWaitDuration;

@property (nonatomic, copy) RespondToOneTapGesture respondToOneTapGesture;
@end

NS_ASSUME_NONNULL_END
