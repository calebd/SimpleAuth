//
//  SimpleAuthProvider.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013-2014 Byliner, Inc. All rights reserved.
//

#import <CMDQueryStringSerialization/CMDQueryStringSerialization.h>

#import "SimpleAuth.h"

@interface SimpleAuthProvider : NSObject

@property (nonatomic, readonly, copy) NSDictionary *options;
@property (nonatomic, readonly) NSOperationQueue *operationQueue;

+ (NSString *)type;
+ (NSDictionary *)defaultOptions;

- (instancetype)initWithOptions:(NSDictionary *)options;
- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion;

@end
