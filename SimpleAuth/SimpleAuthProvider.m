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


+ (void)authorizeWithOptions:(NSDictionary *)options completion:(void (^) (id response))completion {
    [self doesNotRecognizeSelector:_cmd];
}

@end
