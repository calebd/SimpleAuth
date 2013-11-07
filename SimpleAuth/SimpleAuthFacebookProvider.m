//
//  SimpleAuthFacebookProvider.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 SimpleAuth. All rights reserved.
//

#import "SimpleAuthFacebookProvider.h"
#import "SimpleAuth_Internal.h"

@implementation SimpleAuthFacebookProvider

#pragma mark - NSObject

+ (void)load {
    @autoreleasepool {
        [SimpleAuth registerProviderClass:self];
    }
}


#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"facebook";
}


#pragma mark - SimpleAuthSystemProvider

- (void)loadSystemAccount:(SimpleAuthSystemAccountHandler)completion {
    ACAccountStore *store = [[self class] accountStore];
    ACAccountType *type = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [store requestAccessToAccountsWithType:type options:nil completion:^(BOOL granted, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                NSArray *accounts = [store accountsWithAccountType:type];
                NSUInteger numberOfAccounts = [accounts count];
                if (numberOfAccounts == 0) {
                    completion(nil, error ?: [[NSError alloc] initWithDomain:ACErrorDomain code:ACErrorAccountNotFound userInfo:nil]);
                }
                else {
                    completion([accounts lastObject], nil);
                }
            }
            else {
                completion(nil, error ?: [[NSError alloc] initWithDomain:ACErrorDomain code:ACErrorPermissionDenied userInfo:nil]);
            }
        });
    }];
}


- (void)authorizeWithSystemAccount:(ACAccount *)account completion:(SimpleAuthRequestHandler)completion {
    
}


@end
