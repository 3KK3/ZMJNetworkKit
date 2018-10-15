//
//  ZMJRequestManager.h
//  ZMJNetworkKit
//
//  Created by YZY on 2018/10/12.
//  Copyright © 2018 3kk3. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ZMJRequest;

NS_ASSUME_NONNULL_BEGIN

typedef void (^SuccessBlock)(id responseObj);

typedef void (^FailedBlock)(NSError *error);

@interface ZMJRequestManager : NSObject

+ (instancetype)sharedInstance;

- (void)sendRequest:(ZMJRequest *)request successBlock:(SuccessBlock)successBlock failedBlock:(FailedBlock)failedBlock;

- (void)cancelRequests:(NSArray <ZMJRequest *>*)requests;

@end

NS_ASSUME_NONNULL_END
