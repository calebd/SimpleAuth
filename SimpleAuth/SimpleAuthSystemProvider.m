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

#pragma mark - SimpleAuthProvider

- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion {
    [self loadSystemAccount:^(ACAccount *account, NSError *error) {
        if (!account) {
            completion(nil, nil, error);
            return;
        }
        [self authorizeWithSystemAccount:account completion:completion];
    }];
}


#pragma mark - Public

+ (ACAccountStore *)accountStore {
    static dispatch_once_t token;
    static ACAccountStore *store;
    dispatch_once(&token, ^{
        store = [[ACAccountStore alloc] init];
    });
    return store;
}


- (void)loadSystemAccount:(SimpleAuthSystemAccountHandler)completion {
    [self doesNotRecognizeSelector:_cmd];
}


- (void)authorizeWithSystemAccount:(ACAccount *)account completion:(SimpleAuthRequestHandler)completion {
    [self doesNotRecognizeSelector:_cmd];
}

@end
