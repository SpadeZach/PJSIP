//
//  BtnViewController.m
//  SimpleSipPhone
//
//  Created by 赵博 on 2017/7/7.
//  Copyright © 2017年 赵博. All rights reserved.
//

#import "BtnViewController.h"
#import <pjsua-lib/pjsua.h>
@interface BtnViewController ()
{
    pjsua_call_id _call_id;
    UIWebView *callWebview;
}
@property (weak, nonatomic) IBOutlet UIImageView *headerImg;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headerImgX;
@property (weak, nonatomic) IBOutlet UIButton *clickBtn;
@property (weak, nonatomic) IBOutlet UIButton *colseBtn;

@end

@implementation BtnViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleCallStatusChanged:)
                                                 name:@"SIPCallStatusChangedNotification"
                                               object:nil];
  
}
//呼叫
- (IBAction)callPhone:(id)sender {
    [self __processMakeCall];

    [UIView animateWithDuration:2 animations:^{
        self.headerImgX.constant = 140;
        [self.colseBtn setHidden:NO];
    }];
    [sender setEnabled:NO];
}

- (void)handleCallStatusChanged:(NSNotification *)notification {
    pjsua_call_id call_id = [notification.userInfo[@"call_id"] intValue];
    pjsip_inv_state state = [notification.userInfo[@"state"] intValue];
    
    if(call_id != _call_id) return;
    
    
    if (state == PJSIP_INV_STATE_DISCONNECTED) {
        //会话终止
        NSLog(@"~~~~~~会话终止");
        [self.colseBtn setHidden:YES];
        self.headerImgX.constant = 10;
        
        [self.clickBtn setEnabled:YES];
    } else if(state == PJSIP_INV_STATE_CONNECTING){
        NSLog(@"正在连接...");
    } else if(state == PJSIP_INV_STATE_CONFIRMED) {
//        [self.clickBtn setTitle:@"挂断" forState:UIControlStateNormal];
        [self.clickBtn setEnabled:YES];
    }
}
- (void)__processMakeCall {
    pjsua_acc_id acct_id = (pjsua_acc_id)[[NSUserDefaults standardUserDefaults] integerForKey:@"login_account_id"];
    NSString *server = [[NSUserDefaults standardUserDefaults] stringForKey:@"server_uri"];
    NSString *targetUri = [NSString stringWithFormat:@"sip:%@@%@",@"1003", @"172.17.17.131"];
    
    pj_status_t status;
    pj_str_t dest_uri = pj_str((char *)targetUri.UTF8String);
    
    status = pjsua_call_make_call(acct_id, &dest_uri, 0, NULL, NULL, &_call_id);
    
    if (status != PJ_SUCCESS) {
        char  errMessage[PJ_ERR_MSG_SIZE];
        pj_strerror(status, errMessage, sizeof(errMessage));
        NSLog(@"外拨错误, 错误信息:%d(%s) !", status, errMessage);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"外拨错误" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
        [alert show];
        
    }
    //    NSMutableString * str=[[NSMutableString alloc] initWithFormat:@"sip:%@@%@", self.phoneNumberFiled.text , server];
    [callWebview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:targetUri]]];
    if (!callWebview.subviews) {
        [self.view addSubview:callWebview];
    }
    [self.clickBtn setEnabled:YES];
}
- (IBAction)closeCall:(id)sender {
    [self __processHangup];
    [self.clickBtn setEnabled:YES];
}

- (void)__processHangup {
    pj_status_t status = pjsua_call_hangup(_call_id, 0, NULL, NULL);
    
    if (status != PJ_SUCCESS) {
        const pj_str_t *statusText =  pjsip_get_status_text(status);
        NSLog(@"挂断错误, 错误信息:%d(%s) !", status, statusText->ptr);
    }
}


@end
