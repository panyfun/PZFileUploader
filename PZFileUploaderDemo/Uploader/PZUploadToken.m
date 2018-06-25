//
//  PZUploadToken.m
//  PZFileUploaderDemo
//
//  Created by pany on 2018/6/22.
//  Copyright © 2018年 Pany. All rights reserved.
//

#import "PZUploadToken.h"

#import <pthread.h>

@class PZUploadTokenPool;

@interface PZUploadTokenPoolManager : NSObject {
    pthread_mutex_t lock;
}

@property (nonatomic, strong) NSMutableDictionary<NSString *, PZUploadTokenPool *> *poolDic;

@end

@implementation PZUploadTokenPoolManager

+ (instancetype)shareSingleton {
    static id _shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareInstance = [[self alloc] init];
    });
    return _shareInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        pthread_mutex_init(&lock, NULL);
        _poolDic = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc {
    pthread_mutex_destroy(&lock);
}

- (PZUploadTokenPool *)poolOfKey:(NSString *)key {
    if ([key isKindOfClass:[NSString class]] && key.length > 0) {
        pthread_mutex_lock(&lock);
        PZUploadTokenPool *pool = [_poolDic objectForKey:key];
        if (![pool isKindOfClass:[PZUploadTokenPool class]]) {
            pool = [PZUploadTokenPool new];
            [_poolDic setValue:pool forKey:key];
        }
        pthread_mutex_unlock(&lock);
        return pool;
    } else {
        return nil;
    }
}

@end


@interface PZUploadTokenPool ()

@property (nonatomic, strong) NSMutableArray<PZUploadToken *> *container;

@end

@implementation PZUploadTokenPool

+ (instancetype)poolOfType:(NSString *)type {
    return [[PZUploadTokenPoolManager shareSingleton] poolOfKey:type];
}

- (NSArray<PZUploadToken *> *)allToken {
    return [_container copy];
}

- (PZUploadToken *)anyAvailableToken {
    __block NSMutableArray<PZUploadToken *> *delArray = [NSMutableArray array];
    __block PZUploadToken *availableToken;
    NSTimeInterval currentTiem = [[NSDate date] timeIntervalSince1970] - 1; // 当前时间
    [_container enumerateObjectsUsingBlock:^(PZUploadToken * _Nonnull token, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([token isKindOfClass:[PZUploadToken class]] && token.expiration < currentTiem) {
            // token有效
            availableToken = token;
            *stop = YES;
        }
        // 将无效的token和即将被使用的token加入删除计划
        [delArray addObject:token];
    }];
    
    [_container removeObjectsInArray:delArray];
    
    return availableToken;
}

- (void)addToken:(PZUploadToken *)token {
    if (_container == nil) {
        _container = [NSMutableArray array];
    }
    [_container addObject:token];
}

- (void)removeToken:(PZUploadToken *)token {
    [_container removeObject:token];
}

- (void)addTokenFromArray:(NSArray<PZUploadToken *> *)array {
    [_container addObjectsFromArray:array];
}
- (void)removeTokenInArray:(NSArray<PZUploadToken *> *)array {
    [_container removeObjectsInArray:array];
}

@end



@interface PZUploadToken ()

@end

@implementation PZUploadToken

+ (instancetype)anyAvailabeTokenOfType:(NSString *)type {
    return [[PZUploadTokenPool poolOfType:type] anyAvailableToken];
}

@end
