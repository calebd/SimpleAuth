//
//  SimpleAuthProvider.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 SimpleAuth. All rights reserved.
//

#import "SimpleAuthProvider.h"

@implementation SimpleAuthProvider

+ (NSString *)type {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}


+ (SimpleAuthConfiguration *)configuration {
    return [SimpleAuth configuration][[self type]];
}


- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion {
    [self doesNotRecognizeSelector:_cmd];
}

@end
