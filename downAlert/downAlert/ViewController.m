//
//  ViewController.m
//  downAlert
//
//  Created by Luoh on 2019/11/20.
//  Copyright © 2019 EgooNet. All rights reserved.
//

#import "ViewController.h"
#import "EGNotifyView/EGNotifyView.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIButton * downbutton = [UIButton buttonWithType:UIButtonTypeCustom];
    [downbutton setTitle:@"下单提醒" forState:UIControlStateNormal];
    downbutton.frame = CGRectMake(0, 0, 60, 40);
    downbutton.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height / 2);
    downbutton.titleLabel.font = [UIFont systemFontOfSize:13];
    downbutton.backgroundColor = UIColor.greenColor;
    [downbutton addTarget:self action:@selector(clickToNotify:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:downbutton];
}

- (void)clickToNotify:(UIButton *)sender {
    //判断当前视图是否已加载
    for (int i = 0 ; i < [UIApplication sharedApplication].keyWindow.subviews.count; i ++) {
        if ([[UIApplication sharedApplication].keyWindow.subviews[i].class isEqual:NSClassFromString(@"EGNotifyView")]) {
            [[UIApplication sharedApplication].keyWindow.subviews[i] removeFromSuperview];
            break;
        }
    }
    
    // 自定义配置
    EGNotifyViewConfig *config = [EGNotifyViewConfig defaultNotifyConfig];
    config.notifyStyle = EGNotifyViewStyleFill;
    config.respondToOneTapGesture = ^(BOOL respondOneTap) {
        if (respondOneTap) {
            NSLog(@"跳转至IM界面");
        }
    };
    [EGNotifyView showNotify:@"[收到新消息]" nickName:@"20000号客服" notifyTime:@"现在" showView:[UIApplication sharedApplication].keyWindow config:config];
}
@end
