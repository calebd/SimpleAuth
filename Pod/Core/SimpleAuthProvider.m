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

#pragma mark - Properties

@synthesize operationQueue = _operationQueue;

- (NSOperationQueue *)operationQueue {
    if (!_operationQueue) {
        _operationQueue = [[NSOperationQueue alloc] init];
    }
    return _operationQueue;
}


#pragma mark - Initializers

- (instancetype)initWithOptions:(NSDictionary *)options {
    if ((self = [super init])) {
        self.options = options;
    }
    return self;
}


#pragma mark - Public

+ (NSString *)type {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

+ (NSDictionary *)defaultOptions {
    return @{};
}

- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion {
    [self doesNotRecognizeSelector:_cmd];
}

@end
