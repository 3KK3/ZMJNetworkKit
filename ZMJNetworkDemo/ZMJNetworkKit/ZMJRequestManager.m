//
//  ZMJRequestManager.m
//  ZMJNetworkKit
//
//  Created by YZY on 2018/10/12.
//  Copyright © 2018 3kk3. All rights reserved.
//

#import "ZMJRequestManager.h"
#import <AFNetworking.h>
#import "ZMJRequestCache.h"
#import "ZMJRequest.h"
#import "NSString+MD5.h"
#import "ZMJHttpRequestServer.h"

@interface ZMJRequestManager () <NSCopying, NSMutableCopying>

@property (nonatomic, strong) NSMutableArray <ZMJRequest *> *requestArray;
@property (nonatomic, strong) NSMutableArray <SuccessBlock> *successBlockArray;
@property (nonatomic, strong) NSMutableArray <FailedBlock> *failedBlockArray;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSURLSessionDataTask *> *taskDic;

@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, strong) dispatch_queue_t addRuquestQueue;

@property (nonatomic, strong) NSTimer *timer;

@end

static ZMJRequestManager *_instance = nil;
static const int _maxRequestConcurrentNum = 3;

@implementation ZMJRequestManager

+ (instancetype)sharedInstance {
    static dispatch_once_t once_t;
    dispatch_once(&once_t, ^{
        _instance = [[super allocWithZone: NULL] init];
    });
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [ZMJRequestManager sharedInstance];
}

- (id)copyWithZone:(struct _NSZone *)zone {
    return [ZMJRequestManager sharedInstance];
}

- (id)mutableCopyWithZone:(struct _NSZone *)zone {
    return [ZMJRequestManager sharedInstance];
}

- (instancetype)init {
    if (self = [super init]) {
        self.semaphore = dispatch_semaphore_create(_maxRequestConcurrentNum);
        [self startTimer];
    }
    return self;
}

- (void)sendRequest:(ZMJRequest *)request successBlock:(SuccessBlock)successBlock failedBlock:(FailedBlock)failedBlock {
    if (ZMJRequestRetryPolicyStoreToDB == request.retryPolicy) {
        [[ZMJRequestCache sharedInstance] cacheRequest: request];
    }
    [self queueAddRequest: request successBlock: successBlock failedBlock: failedBlock];
}

- (void)queueAddRequest:(ZMJRequest *)request successBlock:(SuccessBlock)successBlock failedBlock:(FailedBlock)failedBlock {
    if (nil == request) {
        return;
    }
    
    dispatch_async(self.addRuquestQueue, ^{
        
        if ([self.requestArray containsObject: request]) {
            return ;
        }
        
//        switch (request.samePolicy) {
//            case ZYSameRequestPolicyCurrent: {
//
//                NSURLSessionDataTask *task = [self.taskDic objectForKey: [self requestMD5WithRequest: request]];
//                if (task) {
//                    continue;
//                }
//            }
//                break;
//            case ZYSameRequestPolicyIgnoreLast: {
//                NSURLSessionDataTask *task = [self.taskDic objectForKey: [self requestMD5WithRequest: request]];
//                if (NSURLSessionTaskStateRunning == task.state || NSURLSessionTaskStateSuspended == task.state) {
//                    [task cancel];
//                }
//            }
//                break;
//        }
        
        
        [self.requestArray addObject: request];
        [self.successBlockArray addObject: successBlock];
        [self.failedBlockArray addObject: failedBlock];
        
        [self dealRequestQueue];
    });
}

- (void)dealRequestQueue {
    //在子线程轮询，以免阻塞主线程
    //让请求按队列先后顺序发送
    
    while (self.requestArray.count > 0) {

        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        //利用AFN发送请求
        
        ZMJRequest *request = self.requestArray.firstObject;
        SuccessBlock successBlock = self.successBlockArray.firstObject;
        FailedBlock failedBlock = self.failedBlockArray.firstObject;
        [self queueRemoveObjAtIndex: 0];
        NSURLSessionDataTask *task = nil;
        
        switch (request.method) {
            case ZMJRequestTypeGet:
            case ZMJRequestTypePost:
            case ZMJRequestTypeDelete:
            case ZMJRequestTypePut: {
                
                task = [[ZMJHttpRequestServer sharedInstance] requestWithPath: request.urlStr method:request.method parameters:request.params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                    
                    dispatch_semaphore_signal(self.semaphore);
                    [self.taskDic removeObjectForKey: [self requestMD5String: request]];

                    if (request.cacheKey) {
                        NSError *error = nil;
                        NSData *data = [NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingPrettyPrinted error:&error];
                        
                        if (!error) {
                            [[ZMJRequestCache sharedInstance] saveData:data ForKey:request.cacheKey];
                        }
                    }
                    
                    //在成功的时候移除数据库中的缓存
                    if (request.retryPolicy == ZMJRequestRetryPolicyStoreToDB) {
                        [[ZMJRequestCache sharedInstance] deleteRequestFromDBWhere: request.requestId];
                    }
                    successBlock(responseObject);
                } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
                    
                    dispatch_semaphore_signal(self.semaphore);
                    //请求失败之后，根据约定的错误码判断是否需要再次请求
                    //这里，-1001是AFN的超时error
                    if (error.code == -1001 &&request.retryCount > 0) {
                        [request reduceRetryCount];
                        [self queueAddRequest: request successBlock: successBlock failedBlock: failedBlock];
                        [self dealRequestQueue];
                    } else {  //处理错误信息
                        [self.taskDic removeObjectForKey: [self requestMD5String: request]];
                        failedBlock(error);
                    }
                }];
            }
                break;
            
            case ZMJRequestTypeHead: {
                task = [[ZMJHttpRequestServer sharedInstance] requestWithPathInHEAD: request.urlStr parameters:request.params success:^(NSURLSessionDataTask * _Nonnull task) {
                    
                    dispatch_semaphore_signal(self.semaphore);
                    [self.taskDic removeObjectForKey: [self requestMD5String: request]];
                    
                    //在成功的时候移除数据库中的缓存
                    if (request.retryPolicy == ZMJRequestRetryPolicyStoreToDB) {
                        [[ZMJRequestCache sharedInstance] deleteRequestFromDBWhere: request.requestId];
                    }
                    successBlock(task);
                } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
                    
                    dispatch_semaphore_signal(self.semaphore);
                    //请求失败之后，根据约定的错误码判断是否需要再次请求
                    //这里，-1001是AFN的超时error
                    if (error.code == -1001 &&request.retryCount > 0) {
                        [request reduceRetryCount];
                        [self queueAddRequest: request successBlock: successBlock failedBlock: failedBlock];
                        [self dealRequestQueue];
                    } else {  //处理错误信息
                        [self.taskDic removeObjectForKey: [self requestMD5String: request]];
                        failedBlock(error);
                    }
                }];
            }
                break;

            case ZMJRequestTypeUpload: {
                task = [[ZMJHttpRequestServer sharedInstance] uploadWithURL: request.urlStr parameters:request.params data:request.uploadData name:request.serverName fileName:request.serverFileNamel success:^(id  _Nonnull responseObject) {
                    
                    dispatch_semaphore_signal(self.semaphore);
                    [self.taskDic removeObjectForKey: [self requestMD5String: request]];
                    
                    //在成功的时候移除数据库中的缓存
                    if (request.retryPolicy == ZMJRequestRetryPolicyStoreToDB) {
                        [[ZMJRequestCache sharedInstance] deleteRequestFromDBWhere: request.requestId];
                    }
                    successBlock(task);
                    
                    
                } failure:^(NSError * _Nonnull error) {
                    
                    dispatch_semaphore_signal(self.semaphore);
                    //请求失败之后，根据约定的错误码判断是否需要再次请求
                    //这里，-1001是AFN的超时error
                    if (error.code == -1001 &&request.retryCount > 0) {
                        [request reduceRetryCount];
                        [self queueAddRequest: request successBlock: successBlock failedBlock: failedBlock];
                        [self dealRequestQueue];
                    } else {  //处理错误信息
                        [self.taskDic removeObjectForKey: [self requestMD5String: request]];
                        failedBlock(error);
                    }
                }];
            }
                break;
        }
        
        [self.taskDic setObject: task forKey: [self requestMD5String: request]];
    }
}

- (NSString *)requestMD5String:(ZMJRequest *)request {
    return [[NSString stringWithFormat: @"%@%@",request.urlStr, request.params] MD5Hash];
}

- (void)queueRemoveObjAtIndex:(NSInteger)index {
    if (self.requestArray.count > index) {
        [self.requestArray removeObjectAtIndex:index];
        [self.successBlockArray removeObjectAtIndex:index];
        [self.failedBlockArray removeObjectAtIndex:index];
    }
}

- (void)startTimer {
    self.timer = [NSTimer scheduledTimerWithTimeInterval: 60 target:self selector:@selector(updateTimer) userInfo:nil repeats:true];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

- (void)updateTimer {
    NSArray *requestArray = [[ZMJRequestCache sharedInstance] allCachedRequests];
    
    if (requestArray != nil && requestArray.count > 0){
        //需要注意的是，存入数据库里面的request是不需要回调的
        //必定成功，当然如果需要更新时间戳的话，可以重新拼接参数的时间戳
        [requestArray enumerateObjectsUsingBlock:^(ZMJRequest *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self queueAddRequest:[obj copy] successBlock: nil failedBlock: nil];
        }];
        [self dealRequestQueue];
    }
}

- (void)cancelRequests:(NSArray<ZMJRequest *> *)requests {
    NSInteger i = 0;
    for (ZMJRequest *request in requests) {
        if (request.canCancel) {
            [self queueRemoveObjAtIndex: i];
            NSURLSessionDataTask *task = [self.taskDic objectForKey: [self requestMD5String: request]];
            if (NSURLSessionTaskStateRunning == task.state || NSURLSessionTaskStateSuspended == task.state) {
                [task cancel];
            }
            //在成功的时候移除realm数据库中的缓存
            if (request.retryPolicy == ZMJRequestRetryPolicyStoreToDB) {
                [[ZMJRequestCache sharedInstance] deleteRequestFromDBWhere: request.requestId];
            }
        }
        i ++;
    }
}

#pragma mark - getter && setter
- (NSMutableArray *)requestArray {
    if (!_requestArray) {
        _requestArray = [NSMutableArray array];
    }
    return _requestArray;
}

- (NSMutableArray *)successBlockArray {
    if (!_successBlockArray) {
        _successBlockArray = [NSMutableArray array];
    }
    return _successBlockArray;
}

- (NSMutableArray *)failedBlockArray {
    if (!_failedBlockArray) {
        _failedBlockArray = [NSMutableArray array];
    }
    return _failedBlockArray;
}

- (dispatch_queue_t)addRuquestQueue {
    if (!_addRuquestQueue) {
        _addRuquestQueue = dispatch_queue_create("com.MZJNetwork.www", DISPATCH_QUEUE_SERIAL);
    }
    return _addRuquestQueue;
}

@end
