//
//  ZMJHttpRequestServer.h
//  ZMJNetworkKit
//
//  Created by YZY on 2018/10/12.
//  Copyright © 2018 ZMJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZMJRequestDefine.h"
@class AFHTTPRequestSerializer;
@class AFHTTPResponseSerializer;

NS_ASSUME_NONNULL_BEGIN

@interface ZMJHttpRequestServer : NSObject
@property (nonatomic, strong) AFHTTPRequestSerializer *requestSerializer;
@property (nonatomic, strong) AFHTTPResponseSerializer *responseSerializer;
+ (instancetype)sharedInstance;

// 监听网络状态，判断是否有网
- (void)startMonitoringNetwork;

/**
 *  HTTP请求（GET、POST、DELETE、PUT）
 */
- (NSURLSessionDataTask *)requestWithPath:(NSString *)url method:(ZMJRequestType)method parameters:(id)parameters success:(void(^)(NSURLSessionDataTask *task,id responseObject))success failure:(void(^)(NSURLSessionDataTask *task,NSError *error))failure;

/**
 *  HTTP请求（HEAD）
 */
- (NSURLSessionDataTask *)requestWithPathInHEAD:(NSString *)url
                   parameters:(NSDictionary *)parameters
                      success:(void (^)(NSURLSessionDataTask *task))success
                      failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;
/**
 *  图片上传方法
 *
 *  @param URL        请求url
 *  @param parameters 需要的参数
 *  @param data       上传的文件
 *  @param name       上传到服务器中接受该文件的字段名，不能为空
 *  @param fileName   存到服务器中的文件名，不能为空
 */
- (NSURLSessionDataTask *)uploadWithURL:(NSString *)URL
           parameters:(id)parameters
                data:(NSData *)data
                 name:(NSString *)name
             fileName:(NSString *)fileName
              success:(void(^)(id responseObject))success
              failure:(void(^)(NSError *error))failure;

@end

NS_ASSUME_NONNULL_END
