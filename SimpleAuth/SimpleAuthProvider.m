//
//  SimpleAuthProvider.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013-2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthProvider.h"

@interface SimpleAuthProvider ()

@property (nonatomic, copy) NSDictionary *options;

@end

@implementation SimpleAuthProvider

@synthesize operationQueue = _operationQueue;

#pragma mark - Public

+ (NSString *)type {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}


+ (NSDictionary *)defaultOptions {
    return @{};
}


- (instancetype)initWithOptions:(NSDictionary *)options {
    if ((self = [super init])) {
        self.options = options;
    }
    return self;
}


- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion {
    [self doesNotRecognizeSelector:_cmd];
}


#pragma mark - Accessors

- (NSOperationQueue *)operationQueue {
    if (!_operationQueue) {
        _operationQueue = [NSOperationQueue new];
    }
    return _operationQueue;
}

@end
