//
//  PZFileTypeBase.m
//  PZFileUploaderDemo
//
//  Created by pany on 2018/6/22.
//  Copyright © 2018年 Pany. All rights reserved.
//

#import "PZFileTypeBase.h"

#import <pthread.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

#import <Qiniu/QiniuSDK.h>

#import "PZUploadToken.h"

#define kPZFileTypeBaseTokenType NSStringFromClass([self class])

@interface PZFileTypeBase ()

@end

@implementation PZFileTypeBase

#pragma mark - Public
- (void)upload:(id)file withParams:(__kindof NSDictionary *)params progressBlock:(PZFileUploaderProgressBlock)progress succBlock:(PZFileUploaderSuccBlock)succ failBlock:(PZFileUploaderFailBlock)fail {
    if (!file) {
        return;
    }
    
    PZUploadToken *token = [self getOneToken];
    if (token) {
        // 生成七牛可选参数
        __block BOOL cancelUpload = NO;
        QNUploadOption *uploadOption = [[QNUploadOption alloc] initWithMime:self.mime progressHandler:^(NSString *key, float percent) {
            if (progress) {
                progress(key, percent, &cancelUpload);
            }
        } params:params checkCrc:NO cancellationSignal:^BOOL{
            return cancelUpload;
        }];
        
        // 上传文件到七牛
        [self qiniuUploadFile:file withKey:token.key token:token.token option:uploadOption complete:^(NSString *uploadKey, BOOL uploadSucc, NSDictionary *info) {
            if (uploadSucc && succ) {
                succ(uploadKey, info);
            } else if (!uploadSucc && fail) {
                fail(uploadKey, info);
            }
        }];
    } else if (fail) {
        NSDictionary *failInfo;
        // TODO: 组织更具体的相关返回信息
        fail(nil, failInfo);
    }
}

#pragma mark - Private
- (PZUploadToken *)getOneToken {
    PZUploadToken *token = [PZUploadToken anyAvailabeTokenOfType:kPZFileTypeBaseTokenType];
    if (token) {
        return token;
    } else {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        // 请求token 并添加到token池
        [self requestToken:^(BOOL succ, NSArray *tokens) {
            if (succ) {
                [[PZUploadTokenPool poolOfType:kPZFileTypeBaseTokenType] addTokenFromArray:tokens];
            }
            dispatch_semaphore_signal(semaphore);
        }];
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        token = [PZUploadToken anyAvailabeTokenOfType:kPZFileTypeBaseTokenType];
    }
    return token;
}

- (void)requestToken:(void(^)(BOOL succ, NSArray *tokens))completion {
    // TODO: 请求token，可以进行失败重试
}


- (void)qiniuUploadFile:(id)file withKey:(NSString *)key token:(NSString *)token option:(QNUploadOption *)option complete:(void(^)(NSString *uploadKey, BOOL uploadSucc, NSDictionary *info))completion {
    QNUploadManager *manager = [QNUploadManager sharedInstanceWithConfiguration:[QNConfiguration new]];
    
    // 对不同类型的文件源进行处理
    if ([file isKindOfClass:[NSData class]]) {
        [manager putData:file key:key token:token complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
            [self qiniuUploadFinishWith:info key:key resp:resp callback:completion];
        } option:option];
    } else if ([file isKindOfClass:[NSString class]] && [[NSFileManager defaultManager] fileExistsAtPath:file]) {
        [manager putFile:file key:file token:token complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
            [self qiniuUploadFinishWith:info key:key resp:resp callback:completion];
        } option:option];
    } else if ([file isKindOfClass:[ALAsset class]]) {
        [manager putALAsset:file key:key token:token complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
            [self qiniuUploadFinishWith:info key:key resp:resp callback:completion];
        } option:option];
    } else if ([file isKindOfClass:[PHAsset class]]) {
        [manager putPHAsset:file key:key token:token complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
            [self qiniuUploadFinishWith:info key:key resp:resp callback:completion];
        } option:option];
    } else if ([file isKindOfClass:[PHAssetResource class]]) {
        [manager putPHAssetResource:file key:key token:token complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
            [self qiniuUploadFinishWith:info key:key resp:resp callback:completion];
        } option:option];
    } else {
        if (completion) {
            // TODO: 组织更具体的相关返回信息
            completion(key, NO, nil);
        }
    }
}

- (void)qiniuUploadFinishWith:(QNResponseInfo *)info key:(NSString *)key resp:(NSDictionary *)resp callback:(void(^)(NSString *uploadKey, BOOL uploadSucc, NSDictionary *info))callback {
    BOOL succ = resp != nil;
    if (callback) {
        // TODO: 组织更具体的相关返回信息
        callback(key, succ, resp);
    }
}

@end
