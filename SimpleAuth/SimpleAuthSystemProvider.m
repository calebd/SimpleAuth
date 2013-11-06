//
//  SimpleAuthSystemProvider.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 SimpleAuth. All rights reserved.
//

#import "SimpleAuthSystemProvider.h"

@import Accounts;

@implementation SimpleAuthSystemProvider

#pragma mark - Public

+ (ACAccountStore *)accountStore {
    static dispatch_once_t token;
    static ACAccountStore *store;
    dispatch_once(&token, ^{
        store = [[ACAccountStore alloc] init];
    });
    return store;
}

@end
