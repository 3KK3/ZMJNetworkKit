//
//  ZMJRequestCache.m
//  ZMJNetworkKit
//
//  Created by YZY on 2018/10/12.
//  Copyright © 2018 3kk3. All rights reserved.
//

#import "ZMJRequestCache.h"
#import "NSString+MD5.h"

static ZMJRequestCache *_instance = nil;

@interface ZMJRequestCache () <NSCopying, NSMutableCopying>

@end

@implementation ZMJRequestCache

+ (instancetype)sharedInstance {
    static dispatch_once_t once_t;
    dispatch_once(&once_t, ^{
        _instance = [[super allocWithZone: NULL] init];
    });
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [ZMJRequestCache sharedInstance];
}

- (id)copyWithZone:(struct _NSZone *)zone {
    return [ZMJRequestCache sharedInstance];
}

- (id)mutableCopyWithZone:(struct _NSZone *)zone {
    return [ZMJRequestCache sharedInstance];
}

- (NSArray <ZMJRequest *>*)allCachedRequests {
    // TODO:
    return @[];
}

- (void)saveData:(NSData *)data ForKey:(NSString *)key {
    NSString *md5 = [key MD5Hash];
    NSString *dir = [NSHomeDirectory() stringByAppendingFormat:@"%@",@"/Library/Caches"];
    
    NSFileManager *mgr = [NSFileManager defaultManager];
    [mgr createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *path = [NSString stringWithFormat:@"%@/%@",dir,md5];
    if ([mgr fileExistsAtPath:path])
    {
        [mgr removeItemAtPath:path error:nil];
    }
    [data writeToFile:path atomically:YES];
}

+ (NSData *)readDataFromFileByUrl:(NSString *)url {
    NSString *md5 = [url MD5Hash];
    NSString *dir = [NSHomeDirectory() stringByAppendingFormat:@"%@",@"/Library/Caches"];
    NSString *path = [NSString stringWithFormat:@"%@/%@",dir,md5];
    return [NSData dataWithContentsOfFile:path];
}

- (void)saveRequestToDB:(ZMJRequest *)request {
    // TODO:
}

- (void)deleteRequestFromDBWhere:(id)requestID {
    // TODO:
}

+ (void)saveValue:(id)value forKey:(NSString *)key {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:value forKey:key];
    [userDefaults synchronize];
}

+ (id)valueWithKey:(NSString *)key {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:key];
}

@end
