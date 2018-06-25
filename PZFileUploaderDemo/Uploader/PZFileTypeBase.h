//
//  PZFileTypeBase.h
//  PZFileUploaderDemo
//
//  Created by pany on 2018/6/22.
//  Copyright © 2018年 Pany. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PZUploadToken;

typedef void (^PZFileUploaderSuccBlock)(NSString *key, NSDictionary *succInfo);
typedef void (^PZFileUploaderFailBlock)(NSString *key, NSDictionary *failInfo);
typedef void (^PZFileUploaderProgressBlock)(NSString *key, float percent, BOOL *cancel);

@interface PZFileTypeBase : NSObject

/**
 请求token的url,
 可以直接在PZFileUploader中配置
 */
@property (nonatomic, copy) NSString *tokenUrl;

@property (nonatomic, copy) NSString *mime; /**< 指定mime类型 */

- (void)upload:(id)file withParams:(__kindof NSDictionary *)params progressBlock:(PZFileUploaderProgressBlock)progress succBlock:(PZFileUploaderSuccBlock)succ failBlock:(PZFileUploaderFailBlock)fail;

//- (PZUploadToken *)getOneToken;

- (void)requestToken:(void(^)(BOOL succ, NSArray<PZUploadToken *> *tokens))completion;

@end
