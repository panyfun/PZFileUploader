//
//  PZUploadToken.m
//  PZFileUploaderDemo
//
//  Created by Pany on 2018/6/22.
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


@interface PZUploadTokenPool () {
    pthread_mutex_t poolLock;
}

@property (nonatomic, strong) NSMutableArray<PZUploadToken *> *container;
@end

@implementation PZUploadTokenPool

- (instancetype)init {
    if (self = [super init]) {
        pthread_mutex_init(&poolLock, nil);
    }
    return self;
}

- (void)dealloc {
    pthread_mutex_destroy(&poolLock);
}

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
    pthread_mutex_lock(&poolLock);
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
    pthread_mutex_unlock(&poolLock);
    
    return availableToken;
}

- (void)addToken:(PZUploadToken *)token {
    pthread_mutex_lock(&poolLock);
    if (_container == nil) {
        _container = [NSMutableArray array];
    }
    [_container addObject:token];
    pthread_mutex_unlock(&poolLock);
}

- (void)removeToken:(PZUploadToken *)token {
    pthread_mutex_lock(&poolLock);
    [_container removeObject:token];
    pthread_mutex_unlock(&poolLock);
}

- (void)addTokenFromArray:(NSArray<PZUploadToken *> *)array {
    pthread_mutex_lock(&poolLock);
    [_container addObjectsFromArray:array];
    pthread_mutex_unlock(&poolLock);
}

- (void)removeTokenInArray:(NSArray<PZUploadToken *> *)array {
    pthread_mutex_lock(&poolLock);
    [_container removeObjectsInArray:array];
    pthread_mutex_unlock(&poolLock);
}

@end



@interface PZUploadToken ()

@end

@implementation PZUploadToken

+ (instancetype)anyAvailabeTokenOfType:(NSString *)type {
    return [[PZUploadTokenPool poolOfType:type] anyAvailableToken];
}

@end
