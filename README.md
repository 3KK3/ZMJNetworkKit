对AFNetwork的二次封装 
实现请求取消、重复请求处理、请求缓存等功能


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
