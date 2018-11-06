//
//  ZMJRequest.h
//  ZMJNetworkKit
//
//  Created by YZY on 2018/10/12.
//

#import <Foundation/Foundation.h>
#import "ZMJRequestDefine.h"
@class AFHTTPRequestSerializer;
@class AFHTTPResponseSerializer;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ZMJRequestRetryPolicy){
    
    // 如果没有发送成功，就放入调度队列再次发送 默认
    ZMJRequestRetryPolicyNormal,
    
    // 必须要成功的请求，如果不成功就存入DB，然后在网络好的情况下继续发送，类似微信发消息
    // 需要注意的是，这类请求不需要回调的
    // 类似于发微信成功与否
    // 就是必定成功的请求，只需要在有网的状态下，必定成功
    ZMJRequestRetryPolicyStoreToDB,
    
    // 普通请求，成不成功不影响业务，不需要重新发送
    ZMJRequestRetryPolicyOnce
};

typedef NS_ENUM(NSInteger, ZMJRequestSamePolicy){
    // 忽略上次请求 默认
    ZMJRequestSamePolicyIgnoreLast,
    // 忽略本次请求
    ZMJRequestSamePolicyIgnoreCurrent
};

@interface ZMJRequest : NSObject <NSCopying>

// 存入数据库的唯一标示
@property (nonatomic, copy, readonly) NSString *requestId;

// 请求参数对
@property (nonatomic, strong) NSDictionary *params;

// 请求url
@property (nonatomic, copy) NSString *urlStr;

// 请求重发策略，默认重发
@property (nonatomic, assign) ZMJRequestRetryPolicy retryPolicy;

// 重复请求处理策略
@property (nonatomic, assign) ZMJRequestSamePolicy samePolicy;

// 请求方法，默认get请求
@property (nonatomic, assign) ZMJRequestType method;

// 是否需要缓存响应的数据，如果cacheKey为nil，就不会缓存响应的数据
@property (nonatomic, copy) NSString *cacheKey;

// 请求没发送成功，重新发送的次数 默认三次
@property (nonatomic, assign) NSInteger retryCount;

// 上传的文件
@property (nonatomic, strong) NSData *uploadData;

// 上传到服务器中接受该文件的字段名，不能为空
@property (nonatomic, copy) NSString *serverName;

// 存到服务器中的文件名，不能为空
@property (nonatomic, copy) NSString *serverFileNamel;

@property (nonatomic, strong) AFHTTPRequestSerializer *requestSerializer;
@property (nonatomic, strong) AFHTTPResponseSerializer *responseSerializer;

- (void)reduceRetryCount;

@end

NS_ASSUME_NONNULL_END
