//
//  PZFileTypeVideo.m
//  PZFileUploaderDemo
//
//  Created by muma on 2018/6/25.
//  Copyright © 2018年 Pany. All rights reserved.
//

#import "PZFileTypeVideo.h"

@implementation PZFileTypeVideo

- (void)requestToken:(void (^)(BOOL, NSArray<PZUploadToken *> *))completion {
    // TODO: 自定义token请求过程
    if (completion) {
        completion(YES, nil);
    }
}

@end
