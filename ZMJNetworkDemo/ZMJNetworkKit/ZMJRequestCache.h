//
//  ZMJRequestCache.h
//  ZMJNetworkKit
//
//  Created by YZY on 2018/10/12.
//  Copyright © 2018 3kk3. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ZMJRequest;

NS_ASSUME_NONNULL_BEGIN

@interface ZMJRequestCache : NSObject

+ (instancetype)sharedInstance;

- (NSArray <ZMJRequest *>*)allCachedRequests;

// 将请求到的data存入沙盒路径
- (void)saveData:(NSData *)data ForKey:(NSString *)key;
// 读取缓存到的数据
+ (NSData *)readDataFromFileByUrl:(NSString *)url;

// 删除缓存的请求
- (void)deleteRequestFromDBWhere:(ZMJRequest *)request;
// 缓存请求
- (void)saveRequestToDB:(ZMJRequest *)request;

+ (void)saveValue:(id)value forKey:(NSString *)key;
+ (id)valueWithKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
