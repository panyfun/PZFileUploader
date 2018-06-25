//
//  PZUploadToken.h
//  PZFileUploaderDemo
//
//  Created by pany on 2018/6/22.
//  Copyright © 2018年 Pany. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PZUploadToken;

@interface PZUploadTokenPool : NSObject

+ (instancetype)poolOfType:(NSString *)type;

- (NSArray<PZUploadToken *> *)allToken;
- (PZUploadToken *)anyAvailableToken;

- (void)addToken:(PZUploadToken *)token;
- (void)removeToken:(PZUploadToken *)token;
- (void)addTokenFromArray:(NSArray<PZUploadToken *> *)array;
- (void)removeTokenInArray:(NSArray<PZUploadToken *> *)array;

@end

@interface PZUploadToken : NSObject

@property (nonatomic) NSTimeInterval expiration;    /**< 有效期时间戳 */
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *key;

+ (instancetype)anyAvailabeTokenOfType:(NSString *)type;

@end
