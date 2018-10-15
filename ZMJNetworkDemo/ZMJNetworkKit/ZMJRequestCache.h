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

- (BOOL)cacheRequest:(ZMJRequest *)request;

//将data存入沙盒路径
- (void)saveData:(NSData *)data ForKey:(NSString *)key;

- (void)deleteRequestFromDBWhere:(NSString *)predicateStr;
- (void)saveRequestToDB:(ZMJRequest *)request;

@end

NS_ASSUME_NONNULL_END
