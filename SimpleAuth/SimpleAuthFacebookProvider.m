//
//  SimpleAuthFacebookProvider.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 SimpleAuth. All rights reserved.
//

#import "SimpleAuthFacebookProvider.h"
#import "SimpleAuth_Internal.h"

#import <SAMCategories/NSDictionary+SAMAdditions.h>

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


+ (NSDictionary *)defaultOptions {
    return @{
        @"permissions" : @[ @"email" ]
    };
}


#pragma mark - SimpleAuthSystemProvider

- (void)loadSystemAccount:(SimpleAuthSystemAccountHandler)completion {
    ACAccountStore *store = [[self class] accountStore];
    ACAccountType *type = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    NSDictionary *options = @{
        ACFacebookAppIdKey : self.options[@"app_id"],
        ACFacebookPermissionsKey : self.options[@"permissions"]
    };
    [store requestAccessToAccountsWithType:type options:options completion:^(BOOL granted, NSError *error) {
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
    [self facebookAccountWithSystemAccount:account completion:^(id responseObject, NSHTTPURLResponse *response, NSError *error) {
        if (responseObject) {
            completion(responseObject, response, error);
        }
        else {
            // Handle error
        }
    }];
}


#pragma mark - Public

- (void)facebookAccountWithSystemAccount:(ACAccount *)account completion:(SimpleAuthRequestHandler)completion {
    NSURL *URL = [NSURL URLWithString:@"https://graph.facebook.com/me"];
    SLRequest *request = [SLRequest
     requestForServiceType:SLServiceTypeFacebook
     requestMethod:SLRequestMethodGET
     URL:URL
     parameters:nil];
    request.account = account;
    [request performRequestWithHandler:^(NSData *data, NSHTTPURLResponse *HTTPResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger statusCode = [HTTPResponse statusCode];
            if (statusCode == 200 && data) {
                NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                completion(dictionary, HTTPResponse, nil);
            }
            else {
                completion(nil, HTTPResponse, error);
            }
        });
    }];
}

@end
