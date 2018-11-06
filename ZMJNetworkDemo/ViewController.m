//
//  ViewController.m
//  ZMJNetworkDemo
//
//  Created by YZY on 2018/10/12.
//  Copyright © 2018 ZMJ. All rights reserved.
//

#import "ViewController.h"
#import "ZMJNetworkKit/ZMJNetwork.h"

@interface ViewController ()
{
    NSMutableArray <ZMJRequest *>*_requests;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _requests = [NSMutableArray array];

}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    // 模拟发送请求
    
    // 1.生成request
    ZMJRequest *request = [[ZMJRequest alloc] init];
    request.params = @{@"uid": @"123456", @"token": @"asfdadfa"};
    request.urlStr = @"https://baidu.com/work/info";
    
    // 2.发送
    [[ZMJRequestManager sharedInstance] sendRequest: request successBlock:^(id  _Nonnull responseObj) {
        
    } failedBlock:^(NSError * _Nonnull error) {
        
    }];
    
    // 3.存储发送的request（可选）
    [_requests addObject: request];
}

// 页面销毁时候取消request
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear: animated];
    
    [[ZMJRequestManager sharedInstance] cancelRequest: _requests.firstObject];
}



@end
