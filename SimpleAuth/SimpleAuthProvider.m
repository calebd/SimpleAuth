//
//  SimpleAuthProvider.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 Seesaw Decisions Corporation. All rights reserved.
//

#import "SimpleAuthProvider.h"

@implementation SimpleAuthProvider

#pragma mark - Public

- (instancetype)initWithOptions:(NSDictionary *)options {
    if ((self = [super init])) {
        _options = [options copy];
    }
    return self;
}


+ (NSString *)type {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}


+ (NSDictionary *)defaultOptions {
    return nil;
}


- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion {
    [self doesNotRecognizeSelector:_cmd];
}

@end
