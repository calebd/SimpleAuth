//
//  SimpleAuthFacebookProvider.m
//  SimpleAuthFacebook
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 Seesaw Decisions Corporation. All rights reserved.
//

#import "SimpleAuthFacebookProvider.h"

#import <SAMCategories/NSDictionary+SAMAdditions.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

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
    [self facebookAccountWithSystemAccount:account completion:^(id responseObject, NSError *error) {
        if (responseObject) {
            completion(responseObject, error);
        }
        else {
            error = error ?: [[NSError alloc] initWithDomain:SimpleAuthErrorDomain code:0 userInfo:nil];
            completion(nil, error);
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
    [request performRequestWithHandler:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger statusCode = [response statusCode];
            if (statusCode == 200 && data) {
                NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                dictionary = [self dictionaryWithResponseObject:dictionary account:account];
                completion(dictionary, nil);
            }
            else {
                completion(nil, error);
            }
        });
    }];
}


#pragma mark - Private

- (NSDictionary *)dictionaryWithResponseObject:(NSDictionary *)responseObject account:(ACAccount *)account {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    
    // Provider
    dictionary[@"provider"] = [[self class] type];
    
    // Credentials
    dictionary[@"credentials"] = @{
        @"token" : account.credential.oauthToken
    };
    
    // User ID
    dictionary[@"uid"] = responseObject[@"id"];
    
    // Raw response
    dictionary[@"extra"] = @{
        @"raw_info" : responseObject
    };
    
    // Profile image
    NSString *avatar = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", responseObject[@"id"]];
    
    // User info
    NSMutableDictionary *user = [NSMutableDictionary new];
    user[@"nickname"] = responseObject[@"username"];
    user[@"email"] = responseObject[@"email"];
    user[@"name"] = responseObject[@"name"];
    user[@"first_name"] = responseObject[@"first_name"];
    user[@"last_name"] = responseObject[@"last_name"];
    user[@"image"] = avatar;
    user[@"location"] = responseObject[@"location"][@"name"];
    user[@"verified"] = responseObject[@"verified"];
    user[@"urls"] = @{
        @"Facebook" : responseObject[@"link"],
    };
    dictionary[@"info"] = user;
    
    return dictionary;
}

@end
