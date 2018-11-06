//
//  ZMJHttpRequestServer.m
//  ZMJNetworkKit
//
//  Created by YZY on 2018/10/12.
//  Copyright © 2018 ZMJ. All rights reserved.
//

#import "ZMJHttpRequestServer.h"
#import <AFNetworking.h>

static ZMJHttpRequestServer *_instance = nil;

@interface ZMJHttpRequestServer () <NSCopying, NSMutableCopying>
@property (nonatomic, strong) AFHTTPSessionManager *manager;
@property (nonatomic, strong) AFNetworkReachabilityManager *reachabilityManager;
@end

@implementation ZMJHttpRequestServer

+ (instancetype)sharedInstance {
    static dispatch_once_t once_t;
    dispatch_once(&once_t, ^{
        _instance = [[super allocWithZone: NULL] init];
    });
    return _instance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self initAFMamager];
    }
    return self;
}

- (void)initAFMamager {
    self.manager = [AFHTTPSessionManager manager];

    //接受内容类型
    self.manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html",@"text/plain",@"text/json",@"application/json", nil];
    
    //超时时间
    [self.manager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
    self.manager.requestSerializer.timeoutInterval = 5.0f;
    [self.manager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
    
    //添加http的header
    //        [self.manager.requestSerializer setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    //        [self.manager.requestSerializer setValue:pKey forHTTPHeaderField:@"pKey"];
    
    //设备相关信息
    NSString *userAgent = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleNameKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], [[UIScreen mainScreen] scale]];
    
    [self.manager.requestSerializer setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    
    //https相关
    //        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
    //        securityPolicy.allowInvalidCertificates = YES;
    //        securityPolicy.validatesDomainName = NO;
    //        self.manager.securityPolicy = securityPolicy;

}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [ZMJHttpRequestServer sharedInstance];
}

- (id)copyWithZone:(NSZone *)zone {
    return [ZMJHttpRequestServer sharedInstance];
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return [ZMJHttpRequestServer sharedInstance];
}

- (void)startMonitoringNetwork {
    self.reachabilityManager = [AFNetworkReachabilityManager manager];
    [self.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusNotReachable: {
                NSLog(@"无网络");
                break;
            }
                
            default:
                NSLog(@"有网络");
                break;
        }
    }];
    [self.reachabilityManager startMonitoring];
}

- (NSURLSessionDataTask *)requestWithPath:(NSString *)url
                                   method:(ZMJRequestType)method
                               parameters:(id)parameters
                                  success:(void (^)(NSURLSessionDataTask *, id))success
                                  failure:(void (^)(NSURLSessionDataTask *, NSError *))failure {
    
    self.manager.requestSerializer = self.requestSerializer;
    self.manager.responseSerializer = self.responseSerializer;
 
    switch (method) {
        case ZMJRequestTypeGet: {
            return [self.manager GET:url parameters:parameters progress:nil success:success failure:failure];
        }
            break;
        case ZMJRequestTypePost: {
            return [self.manager POST:url parameters:parameters progress:nil success:success failure:failure];
        }
            break;
        case ZMJRequestTypeDelete: {
            return [self.manager DELETE:url parameters:parameters success:success failure:failure];
        }
            break;
        case ZMJRequestTypePut: {
            return [self.manager PUT:url parameters:parameters success:success failure:false];
        }
            break;
            
        default:break;
 
    }
    return nil;
}

- (NSURLSessionDataTask *)requestWithPathInHEAD:(NSString *)url
                   parameters:(NSDictionary *)parameters
                      success:(void (^)(NSURLSessionDataTask *task))success
                      failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    
    self.manager.requestSerializer = self.requestSerializer;
    self.manager.responseSerializer = self.responseSerializer;
    
   return [self.manager HEAD:url parameters:parameters success:success failure:failure];
}

#pragma mark - 上传图片方法
- (NSURLSessionDataTask *)uploadWithURL:(NSString *)URL
           parameters:(id)parameters
                 data:(NSData *)data
                 name:(NSString *)name
             fileName:(NSString *)fileName
              success:(void (^)(id _Nonnull))success
              failure:(void (^)(NSError * _Nonnull))failure {
    
    self.manager.requestSerializer = self.requestSerializer;
    self.manager.responseSerializer = self.responseSerializer;
    
    //AFN的上传data
    return [self.manager POST:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        NSString *mimeType = @"image/jpg";
        
        /**
         拼接data到 HTTP body
         mimeType JPG:image/jpg, PNG:image/png, JSON:application/json
         */
        [formData appendPartWithFileData:data name:name fileName:fileName mimeType:mimeType];
        
        //表单拼接参数data
        [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id  obj, BOOL *stop) {
            
            NSString *objStr = [NSString stringWithFormat:@"%@", obj];
            NSData *objData = [objStr dataUsingEncoding:NSUTF8StringEncoding];
            [formData appendPartWithFormData:objData name:key];
        }];
        
    } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        success(responseObject);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        failure(error);
        
    }];
}

- (BOOL)isConnectingNetwork {
    return [AFNetworkReachabilityManager manager].reachable;
}


@end
