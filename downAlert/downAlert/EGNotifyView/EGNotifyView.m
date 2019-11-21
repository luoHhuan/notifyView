//
//  EGNotifyView.m
//  downAlert
//
//  Created by Luoh on 2019/11/20.
//  Copyright © 2019 EgooNet. All rights reserved.
//

#import "EGNotifyView.h"

#define kFontSize(fontSize) fontSize * (kScreenWidth / 375)
#define kScreenWidth [UIScreen mainScreen].bounds.size.width

#define HORIZ_SWIPE_DRAG_MIN_LR  12    //水平滑动最小间距
#define VERT_SWIPE_DRAG_MAX_LR    4    //垂直方向最大偏移量

#define HORIZ_SWIPE_DRAG_MIN_UD  4    //水平滑动最小间距
#define VERT_SWIPE_DRAG_MAX_UD   12    //垂直方向最大偏移量

CGFloat padding = 10.f;
CGFloat textPadding = 15.f;

@interface EGNotifyView () <CAAnimationDelegate>
/** config */
@property (nonatomic, strong) EGNotifyViewConfig * config;
/** mainView */
@property (nonatomic, strong) UIView * mainView;

/** 信息View */
@property (nonatomic, strong) UIView * infoView;
/** 头像 */
@property (nonatomic, strong) UIImageView * iconImageView;
/** 昵称 */
@property (nonatomic, strong) UILabel * nickNameLabel;
/** 消息时间 */
@property (nonatomic, strong) UILabel * notifyTimeLabel;


/** 内容View */
@property (nonatomic, strong) UIView * contentView;
/** 内容 */
@property (nonatomic, strong) UILabel * contentLabel;
/** 回复输入框 */
@property (nonatomic, strong) UITextField * replyTextfield;

/** label */
@property (nonatomic, strong) UILabel * label;
/** notify */
@property (nonatomic, copy) NSString * notify;
/** nickName */
@property (nonatomic, copy) NSString * nickName;
/** notifyTime */
@property (nonatomic, copy) NSString * notifyTime;
/** showView */
@property (nonatomic, strong) UIView * showView;

/** 点击的点 */
@property (nonatomic, assign) CGPoint startTouchPosition;
@property (nonatomic, assign) CGPoint currentTouchPosition;

@end

@implementation EGNotifyView

+ (EGNotifyView *)showNotify:(NSString *)notify nickName:(NSString *)nickName notifyTime:(NSString *)notifyTime{
    return [self showNotify:notify nickName:nickName notifyTime:notifyTime showView:[UIApplication sharedApplication].keyWindow];
}

+ (EGNotifyView *)showNotify:(NSString *)notify nickName:(NSString *)nickName notifyTime:(NSString *)notifyTime showView:(UIView *)showView {
    return [self showNotify:notify nickName:nickName notifyTime:notifyTime showView:showView config:[EGNotifyViewConfig defaultNotifyConfig]];
}

+ (EGNotifyView *)showNotify:(NSString *)notify nickName:(NSString *)nickName notifyTime:(NSString *)notifyTime showView:(UIView *)showView config:(EGNotifyViewConfig *)config {
    if (!config) {
        config = [EGNotifyViewConfig defaultNotifyConfig];
    }
    if (!showView) {
        showView = [UIApplication sharedApplication].keyWindow;
    }
    return [[self alloc] initWithNotify:notify nickName:nickName notifyTime:notifyTime showView:showView config:config];
}

- (EGNotifyView *)initWithNotify:(NSString *)notify nickName:(NSString *)nickName notifyTime:(NSString *)notifyTime showView:(UIView *)showView config:(EGNotifyViewConfig *)config{
    if (self = [super init]) {
        self.notify = notify;
        self.notifyTime = notifyTime;
        self.nickName = nickName;
        self.config = config;
        self.showView = showView;
        
        //初始化UI
        [self initNotifyUI];
        
        //初始化动画
        [self initNotifyAnimation];
    }
    return self;
}

#pragma mark - 初始化动画
- (void)initNotifyAnimation {
    CGPoint fromPoint = self.mainView.center;
    fromPoint.y = -self.mainView.frame.size.height;
    CGPoint oldPoint = self.mainView.center;
    
    if (@available(iOS 9.0, *)) {
        CFTimeInterval settlingDuratoin = 0.f;
        
        if (self.config.notifyStyle == EGNotifyViewStyleFill) {
            CABasicAnimation *fillAnim = [CABasicAnimation animationWithKeyPath:@"position"];
            fillAnim.fromValue = [NSValue valueWithCGPoint:fromPoint];
            fillAnim.toValue = [NSValue valueWithCGPoint:oldPoint];
            fillAnim.removedOnCompletion = NO;
            fillAnim.fillMode = kCAFillModeForwards;
            fillAnim.duration = 0.25;
            [self.mainView.layer addAnimation:fillAnim forKey:nil];
            
            settlingDuratoin = 0.25;
        } else if (self.config.notifyStyle == EGNotifyViewStyleFit) {
            CASpringAnimation *springAnim = [CASpringAnimation animationWithKeyPath:@"position"];
            springAnim.fromValue = [NSValue valueWithCGPoint:fromPoint];
            springAnim.toValue = [NSValue valueWithCGPoint:oldPoint];
            springAnim.removedOnCompletion = NO;
            springAnim.fillMode = kCAFillModeForwards;
            springAnim.stiffness = 60;
            springAnim.duration = springAnim.settlingDuration;
            [self.mainView.layer addAnimation:springAnim forKey:nil];
            
            settlingDuratoin = springAnim.settlingDuration;
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.config.notifyViewWaitDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissNotifyView];
        });
    }
}

- (void)dismissNotifyView {
    CGPoint fromPoint = self.mainView.center;
    fromPoint.y = -self.mainView.frame.size.height;
    CGPoint oldPoint = self.mainView.center;
    
    CABasicAnimation *basicAnim = [CABasicAnimation animationWithKeyPath:@"position"];
    basicAnim.duration = 0.25;
//    basicAnim.beginTime = self.config.notifyViewWaitDuration;
    
    basicAnim.fromValue = [NSValue valueWithCGPoint:oldPoint];
    basicAnim.toValue = [NSValue valueWithCGPoint:fromPoint];
    basicAnim.removedOnCompletion = NO;
    basicAnim.fillMode = kCAFillModeForwards;
    basicAnim.delegate = self;
    [self.mainView.layer addAnimation:basicAnim forKey:nil];
}

#pragma mark - CAAnimationDelegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    [self removeNoiifyViewFromSuperview];
}

#pragma mark - 删除视图
- (void)removeNoiifyViewFromSuperview {
    [self removeFromSuperview];
}

#pragma mark - 初始化UI
- (void)initNotifyUI {
    
    [self.showView addSubview:self];

    padding = [self getStatusHeight];
    CGFloat mainViewX = padding;
    CGFloat mainViewW = kScreenWidth - mainViewX * 2;
    CGFloat mainViewY = padding;
    CGFloat mainViewH = 110;
    
    if (self.config.notifyStyle == EGNotifyViewStyleFill) {
        padding = 0.f + [self getStatusHeight];
        mainViewX = 0;
        mainViewW = kScreenWidth;
        mainViewY = padding;
//        mainViewH = 100;
    }
    self.frame = CGRectMake(mainViewX, mainViewY, mainViewW, mainViewH);
    
    self.mainView = [[UIView alloc] initWithFrame:CGRectMake(mainViewX, 0, mainViewW, mainViewH)];
    self.mainView.backgroundColor = self.config.backgroundColor;
//    if (self.config.notifyStyle == EGNotifyViewStyleFit) {
        self.mainView.layer.cornerRadius = 6.f;
        self.mainView.layer.masksToBounds = YES;
//    }
    [self addSubview:self.mainView];
    
    
    
    self.infoView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, mainViewW, 30)];
    self.infoView.backgroundColor = [self colorWithHexString:@"#eeeeee" alpha:1];
    [self.mainView addSubview:self.infoView];
    
    /** 头像 */
    CGFloat iconWith = 20;
    self.iconImageView = [[UIImageView alloc]init];
    self.iconImageView.frame = CGRectMake(10, 5, iconWith, iconWith);
    self.iconImageView.layer.cornerRadius = iconWith / 2;
    self.iconImageView.layer.masksToBounds = YES;
    [self.infoView addSubview:self.iconImageView];
    self.iconImageView.backgroundColor = UIColor.redColor;
    
    /** 消息时间 */
    CGFloat notifyTimeWidth = 60;
    CGFloat notifyTimeHeight = 20;
    self.notifyTimeLabel = [[UILabel alloc]init];
    self.notifyTimeLabel.textAlignment = NSTextAlignmentRight;
    self.notifyTimeLabel.frame = CGRectMake(0, 0, notifyTimeWidth, notifyTimeHeight);
    self.notifyTimeLabel.center = CGPointMake(kScreenWidth - self.notifyTimeLabel.frame.size.width / 2 - 10, self.iconImageView.center.y);
    self.notifyTimeLabel.font = [UIFont systemFontOfSize:12];
    self.notifyTimeLabel.text = self.notifyTime;
    [self.infoView addSubview:self.notifyTimeLabel];
    
    /** 昵称 */
    CGFloat nickNameWidth = kScreenWidth - self.iconImageView.frame.size.width - self.notifyTimeLabel.frame.size.width - 10 * 4;
    CGFloat nickNameHeight = 20;
    self.nickNameLabel = [[UILabel alloc]init];
    self.nickNameLabel.frame = CGRectMake(0, 0, nickNameWidth, nickNameHeight);
    self.nickNameLabel.center = CGPointMake((kScreenWidth - self.iconImageView.frame.size.width - self.notifyTimeLabel.frame.size.width - 40) / 2 + self.iconImageView.frame.size.width + 20, self.iconImageView.center.y);
    self.nickNameLabel.font = [UIFont systemFontOfSize:12];
    self.nickNameLabel.text = self.nickName;
    [self.infoView addSubview:self.nickNameLabel];
    
    /** 内容View */
    self.contentView = [[UIView alloc]initWithFrame:CGRectMake(0, self.infoView.frame.size.height, mainViewW, mainViewH - self.infoView.frame.size.height)];
    self.contentView.backgroundColor = [self colorWithHexString:@"#D8D8D8" alpha:1];
    [self.mainView addSubview:self.contentView];
    
    /** 内容 */
    self.contentLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 5, self.contentView.frame.size.width - 20, 30)];
    [self.contentView addSubview:self.contentLabel];
    self.contentLabel.font = [UIFont systemFontOfSize:14];
    self.contentLabel.numberOfLines = 0;
    self.contentLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.contentLabel.text = self.notify;
    
    /** 回复框 */
    self.replyTextfield = [[UITextField alloc]init];
    [self.contentView addSubview:self.replyTextfield];
    self.replyTextfield.placeholder = @"回复TA";
    self.replyTextfield.frame = CGRectMake(10, self.contentLabel.frame.size.height + 10, self.contentView.frame.size.width - 20, 30);
    self.replyTextfield.backgroundColor = UIColor.whiteColor;
    self.replyTextfield.layer.cornerRadius = 3;
    self.replyTextfield.layer.masksToBounds = YES;
    self.replyTextfield.font = [UIFont systemFontOfSize:13];
    UIView * leftv = [[UIView alloc]init];
    leftv.frame = CGRectMake(0, 0, 12, 1);
    self.replyTextfield.leftView = leftv;
    self.replyTextfield.leftViewMode = UITextFieldViewModeAlways;
    self.replyTextfield.userInteractionEnabled = NO;
    
//    /** 通知内容 */
//    UIFont *titleFont = [UIFont systemFontOfSize:self.config.textSize];
//    if (@available(iOS 8.2, *)) {
//        titleFont = [UIFont systemFontOfSize:self.config.textSize weight:UIFontWeightMedium];
//    }
//    CGFloat titleLW = self.mainView.frame.size.width - textPadding * 2;
//    CGFloat titleLH = [self getHeightForString:self.notify font:titleFont andWidth:titleLW];
//    CGFloat titleLY = [self getStatusHeight] + 10;
//    if (self.config.notifyStyle == EGNotifyViewStyleFill) {
//        titleLY = textPadding;
//        NSLog(@"%@---%@",self.showView, [UIApplication sharedApplication].keyWindow);
//        if (self.showView == [UIApplication sharedApplication].keyWindow) {
//            titleLY = [self getStatusHeight] + textPadding;
//
//        }
//    }
//    CGFloat titleLX = mainViewW * 0.5 - titleLW * 0.5;
//    self.label = [[UILabel alloc] initWithFrame:CGRectMake(titleLX, titleLY, titleLW, titleLH)];
//    NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
//    ps.lineSpacing = self.config.textLineSpace;
//    self.label.attributedText = [[NSAttributedString alloc] initWithString:self.notify attributes:@{
//                                                                                                    NSFontAttributeName: titleFont,
//                                                                                                    NSParagraphStyleAttributeName: ps,
//                                                                                                    }];
//    self.label.textColor = self.config.textColor;
//    self.label.font = titleFont;
//    self.label.textAlignment = NSTextAlignmentCenter;
//    self.label.numberOfLines = 0;
//    [self.mainView addSubview:self.label];
    
//    CGRect mainViewFrame = self.mainView.frame;
//    mainViewFrame.size.height = CGRectGetMaxY(self.label.frame) + textPadding;
//    self.mainView.frame = mainViewFrame;
}

#pragma mark - 判断是否有刘海
- (BOOL)isIphoneX {
    if (@available(iOS 11.0, *)) {
        if ([UIApplication sharedApplication].windows[0].safeAreaInsets.top > 0) {
            return true;
        } else {
            return false;
        }
    } else {
        return false;
    }
}

#pragma mark - 获取状态栏高度
- (CGFloat)getStatusHeight {
    return [UIApplication sharedApplication].statusBarFrame.size.height;
}

#pragma mark - 根据宽度计算高度
- (CGFloat)getHeightForString:(NSString *)value font:(UIFont *)font andWidth:(CGFloat)width {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = self.config.textLineSpace;
    CGRect rect = [value boundingRectWithSize:CGSizeMake(width, MAXFLOAT)
                                      options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                   attributes:@{
                                                NSFontAttributeName: font,
                                                NSParagraphStyleAttributeName: paragraphStyle,
                                                }
                                      context:nil];
    return rect.size.height;
}

-(UIColor *)colorWithHexString:(NSString *)hexColor alpha:(float)opacity{
    NSString * cString = [[hexColor stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    if ([cString length] < 6) return [UIColor blackColor];
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
    if ([cString hasPrefix:@"#"]) cString = [cString substringFromIndex:1];
    if ([cString length] != 6) return [UIColor blackColor];
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString * rString = [cString substringWithRange:range];
    range.location = 2;
    NSString * gString = [cString substringWithRange:range];
    range.location = 4;
    NSString * bString = [cString substringWithRange:range];
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    return [UIColor colorWithRed:((float)r / 255.0f)
                           green:((float)g / 255.0f)
                            blue:((float)b / 255.0f)
                           alpha:opacity];
}

#pragma mark --
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *aTouch = [touches anyObject];
    // startTouchPosition是一个CGPoint类型的属性，用来存储当前touch事件的位置
    self.startTouchPosition = [aTouch locationInView:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *aTouch in touches) {
        if (aTouch.tapCount == 1) {
            // 处理双击事件
            [self respondToDoubleTapGesture];
        }
    }
    
    UITouch *aTouch = [touches anyObject];
    CGPoint currentTouchPosition = [aTouch locationInView:self];
//    //  判断水平滑动的距离是否达到了设置的最小距离，并且是否是在接近直线的路线上滑动（y轴偏移量）
//    if (fabs(self.startTouchPosition.x - currentTouchPosition.x) >= HORIZ_SWIPE_DRAG_MIN_LR &&
//        fabs(self.startTouchPosition.y - currentTouchPosition.y) <= VERT_SWIPE_DRAG_MAX_LR)
//    {
//        // 满足if条件则认为是一次成功的滑动事件，根据x坐标变化判断是左滑还是右滑
//        if (self.startTouchPosition.x < currentTouchPosition.x) {
//            [self rightSwipe];//右滑响应方法
//        } else {
//            [self leftSwipe];//左滑响应方法
//        }
//        //重置开始点坐标值
//        self.startTouchPosition = CGPointZero;
//    }
    
    if (fabs(self.startTouchPosition.x - currentTouchPosition.x) <= HORIZ_SWIPE_DRAG_MIN_UD &&
        fabs(self.startTouchPosition.y - currentTouchPosition.y) >= VERT_SWIPE_DRAG_MAX_UD)
    {
        // 满足if条件则认为是一次成功的滑动事件，根据x坐标变化判断是左滑还是右滑
        if (self.startTouchPosition.y < currentTouchPosition.y) {
            [self downSwipe];//下滑响应方法
        } else {
            [self upSwipe];//上滑响应方法
        }
        //重置开始点坐标值
        self.startTouchPosition = CGPointZero;
    }
}
-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    //当事件因某些原因取消时，重置开始点坐标值
    self.startTouchPosition = CGPointZero;
}
-(void)rightSwipe
{
//    NSLog(@"rightSwipe");
}
-(void)leftSwipe
{
//    NSLog(@"leftSwipe");
}

-(void)downSwipe
{
//    NSLog(@"downSwipe");
}
-(void)upSwipe
{
//    NSLog(@"upSwipe");
    [self dismissNotifyView];
}
- (void)respondToDoubleTapGesture
{
//    NSLog(@"单击手势");
    [self dismissNotifyView];
    if (self.config.respondToOneTapGesture) {
        self.config.respondToOneTapGesture(true);
    }
}

@end



@implementation UIColor (EGNotifyView)

+(UIColor *)colorWithHexString:(NSString *)hexColor {
    return [self colorWithHexString:hexColor alpha:1];
}

+(UIColor *)colorWithHexString:(NSString *)hexColor alpha:(float)opacity{
    NSString * cString = [[hexColor stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    if ([cString length] < 6) return [UIColor blackColor];
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
    if ([cString hasPrefix:@"#"]) cString = [cString substringFromIndex:1];
    if ([cString length] != 6) return [UIColor blackColor];
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString * rString = [cString substringWithRange:range];
    range.location = 2;
    NSString * gString = [cString substringWithRange:range];
    range.location = 4;
    NSString * bString = [cString substringWithRange:range];
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    return [UIColor colorWithRed:((float)r / 255.0f)
                           green:((float)g / 255.0f)
                            blue:((float)b / 255.0f)
                           alpha:opacity];
}

@end




@implementation EGNotifyViewConfig

+ (EGNotifyViewConfig *)defaultNotifyConfig {
    return [[self alloc] init];
}

- (instancetype)init {
    if (self = [super init]) {
        //初始化配置
        [self initNotifyConfig];
    }
    return self;
}

#pragma mark - 初始化配置
- (void)initNotifyConfig {
    self.notifyStyle = EGNotifyViewStyleFit;
    
    
    self.backgroundColorType = EGNotifyViewBackgroundColorTypeSuccess;
    
    self.textSize = kFontSize(16.f);
    self.textLineSpace = 2.f;
    
    self.textColor = [UIColor blackColor];
    
    self.notifyViewWaitDuration = 2.0f;
}

- (void)setBackgroundColorType:(EGNotifyViewBackgroundColorType)backgroundColorType {
    _backgroundColorType = backgroundColorType;
    
    if (backgroundColorType == EGNotifyViewBackgroundColorTypeSuccess) {
//        self.backgroundColor = [UIColor colorWithHexString:@"#d6e9c6"];
        self.backgroundColor = [UIColor colorWithHexString:@"#eeeeee"];
        self.textColor = [UIColor colorWithHexString:@"#2B5408"];
    } else if (backgroundColorType == EGNotifyViewBackgroundColorTypeInfo) {
        self.backgroundColor = [UIColor colorWithHexString:@"#d9edf7"];
        self.textColor = [UIColor colorWithHexString:@"#245269"];
    } else if (backgroundColorType == EGNotifyViewBackgroundColorTypeDanger) {
        self.backgroundColor = [UIColor colorWithHexString:@"#f2dede"];
        self.textColor = [UIColor colorWithHexString:@"#843534"];
    } else if (backgroundColorType == EGNotifyViewBackgroundColorTypeWarning) {
        self.backgroundColor = [UIColor colorWithHexString:@"#fcf8e3"];
        self.textColor = [UIColor colorWithHexString:@"#66512c"];
    }
}

@end
