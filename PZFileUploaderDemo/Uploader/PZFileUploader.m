//
//  PZFileUploader.m
//  PZFileUploaderDemo
//
//  Created by Pany on 2018/6/22.
//  Copyright © 2018年 Pany. All rights reserved.
//

#import "PZFileUploader.h"

static NSString * const kPZUploadQueueName = @"com.pany.PZFileUploader.taskQueue";
static NSInteger const kPZUploadTaskLimitMax = 5;

@interface PZFileUploader ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *tokenUrlDic;

@property (nonatomic) dispatch_queue_t uploadTaskQueue;   /**< 上传队列 */
@property (nonatomic) dispatch_semaphore_t uploadLock;  /**< 限制同时进行的任务数量 */

@end

@implementation PZFileUploader

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
        _uploadTaskQueue = dispatch_queue_create(kPZUploadQueueName.UTF8String, DISPATCH_QUEUE_SERIAL);
        _uploadLock = dispatch_semaphore_create(kPZUploadTaskLimitMax);
    }
    return self;
}

- (void)configTokenUrl:(NSString *)url forFileType:(Class)typeCls {
    
    if ((url != nil && ![url isKindOfClass:[NSString class]])
        || ![typeCls isSubclassOfClass:NSClassFromString(@"PZFileTypeBase")]) {
        return;
    }
    if (!_tokenUrlDic) {
        _tokenUrlDic = [NSMutableDictionary new];
    }
    NSString *key = NSStringFromClass(typeCls);
    if (url == nil || [url isEqualToString:@""]) {
        [_tokenUrlDic removeObjectForKey:key];
    } else if (url.length > 0) {
        [_tokenUrlDic setValue:url forKey:key];
    }
}

- (void)uploadFile:(id)file ofType:(__kindof PZFileTypeBase *)type withParams:(__kindof NSDictionary *)params progressBlock:(PZFileUploaderProgressBlock)progress succBlock:(PZFileUploaderSuccBlock)succ failBlock:(PZFileUploaderFailBlock)fail {
    // 配置token请求的url
    if (type.tokenUrl == nil) {
        type.tokenUrl = [_tokenUrlDic objectForKey:NSStringFromClass([type class])];
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(_uploadTaskQueue, ^{
        typeof(weakSelf) strongSelf = weakSelf;
        // 串行分发任务到子线程执行
        dispatch_semaphore_wait(strongSelf.uploadLock, DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [type upload:file withParams:params progressBlock:^(NSString *key, float percent, BOOL *cancel) {
                if (progress) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        progress(key, percent, cancel);
                        if (*cancel) {
                            dispatch_semaphore_signal(strongSelf.uploadLock);
                        }
                    });
                }
            } succBlock:^(NSString *key, NSDictionary *succInfo) {
                if (succ) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        succ(key, succInfo);
                    });
                }
                dispatch_semaphore_signal(strongSelf.uploadLock);
            } failBlock:^(NSString *key, NSDictionary *failInfo) {
                if (fail) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        fail(key, failInfo);
                    });
                }
                dispatch_semaphore_signal(strongSelf.uploadLock);
            }];
        });
    });
}

@end
