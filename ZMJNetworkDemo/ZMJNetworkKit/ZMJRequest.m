//
//  ZMJRequest.m
//  ZMJNetworkKit
//
//  Created by YZY on 2018/10/12.
//

#import "ZMJRequest.h"
#import "NSString+MD5.h"
#import <AFNetworking.h>
#import "ZMJRequestCache.h"

@interface ZMJRequest ()
@property (nonatomic, copy, readwrite) NSString *requestId;
@end

@implementation ZMJRequest

- (instancetype)init {
    if (self = [super init]) {
        
        self.retryCount = 3;
        self.retryPolicy = ZMJRequestRetryPolicyNormal;
        self.method = ZMJRequestTypeGet;
        self.cacheKey = self.cacheKey;
        self.samePolicy = ZMJRequestSamePolicyIgnoreLast;
        self.requestSerializer = [AFHTTPRequestSerializer serializer];
        self.responseSerializer = [AFJSONResponseSerializer serializer];
        self.requestId = [self generateReqeustID];
    }
    return self;
}

- (NSString *)generateReqeustID {
    static NSString *const requestKey = @"ZMJGenerateReqeustID";
    
    NSString *ID = [ZMJRequestCache valueWithKey: requestKey];
    NSInteger intID = [ID integerValue];
    intID ++;
    NSString *newID = [NSString stringWithFormat: @"%ld", intID];
    [ZMJRequestCache setValue: newID forKey: requestKey];
    return newID;
}

- (id)copyWithZone:(NSZone *)zone {
    ZMJRequest *request = [[[self class] allocWithZone:zone] init];
    request.requestId = self.requestId;
    request.params = self.params;
    request.urlStr = self.urlStr;
    request.retryPolicy = self.retryPolicy;
    request.method = self.method;
    request.cacheKey = self.cacheKey;
    request.retryCount = self.retryCount;
    request.samePolicy = self.samePolicy;
    return request;
}

- (void)setUrlStr:(NSString *)urlStr {
    _urlStr = urlStr;
}

- (void)setParams:(NSDictionary *)params {
    _params = params;
}

- (void)setRetryPolicy:(ZMJRequestRetryPolicy)retryPolicy {
    _retryPolicy = retryPolicy;
    
    if (ZMJRequestRetryPolicyOnce == retryPolicy) {
        self.retryCount = 1;
    }
}

- (void)reduceRetryCount {
    self.retryCount--;
    if (self.retryCount < 0) self.retryCount = 0;
}

- (BOOL)isEqual:(ZMJRequest *)object {
    if (object == nil) return NO;
    
    if (object.requestId == self.requestId || object == self) return YES;
    
    return NO;
}

@end
