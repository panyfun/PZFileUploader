//
//  PZFileUploader.h
//  PZFileUploaderDemo
//
//  Created by pany on 2018/6/22.
//  Copyright © 2018年 Pany. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PZFileTypeBase.h"

@interface PZFileUploader : NSObject

+ (instancetype)shareSingleton;

- (void)configTokenUrl:(NSString *)url forFileType:(Class)typeCls;

- (void)uploadFile:(id)file ofType:(__kindof PZFileTypeBase *)type withParams:(__kindof NSDictionary *)params progressBlock:(PZFileUploaderProgressBlock)progress succBlock:(PZFileUploaderSuccBlock)succ failBlock:(PZFileUploaderFailBlock)fail;

@end
