//
//  SimpleAuthFacebookProvider.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013-2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthFacebookProvider.h"
#import "ACAccountStore+SimpleAuth.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
@import Social;

@implementation SimpleAuthFacebookProvider

#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"facebook";
}

+ (NSDictionary *)defaultOptions {
    return @{
        @"permissions" : @[ @"email" ],
        @"audience" : @[ ACFacebookAudienceOnlyMe ]
    };
}

- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion {
    [[[[self systemAccount]
        flattenMap:^RACStream *(ACAccount *account) {
            NSArray *signals = @[
                [RACSignal return:account],
                [self remoteAccountWithSystemAccount:account]
            ];
            return [self rac_liftSelector:@selector(responseDictionaryWithSystemAccount:remoteAccount:) withSignalsFromArray:signals];
        }]
        deliverOn:[RACScheduler mainThreadScheduler]]
        subscribeNext:^(NSDictionary *response) {
            completion(response, nil);
        }
        error:^(NSError *error) {
            completion(nil, error);
        }];
}


#pragma mark - Private

- (RACSignal *)allSystemAccounts {
    NSDictionary *options = @{
        ACFacebookAppIdKey : self.options[@"app_id"],
        ACFacebookPermissionsKey : self.options[@"permissions"],
        ACFacebookAudienceKey: self.options[@"audience"]
    };
    return [ACAccountStore SimpleAuth_accountsWithTypeIdentifier:ACAccountTypeIdentifierFacebook options:options];
}

- (RACSignal *)systemAccount {
    return [[self allSystemAccounts] map:^(NSArray *accounts) {
        return [accounts lastObject];
    }];
}

- (RACSignal *)remoteAccountWithSystemAccount:(ACAccount *)account {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSURL *URL = [NSURL URLWithString:@"https://graph.facebook.com/me"];
        SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodGET URL:URL parameters:nil];
        request.account = account;
        [request performRequestWithHandler:^(NSData *data, NSHTTPURLResponse *response, NSError *connectionError) {
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 99)];
            NSInteger statusCode = [response statusCode];
            if ([indexSet containsIndex:statusCode] && data) {
                NSError *parseError = nil;
                NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&parseError];
                if (dictionary) {
                    [subscriber sendNext:dictionary];
                    [subscriber sendCompleted];
                }
                else {
                    NSMutableDictionary *dictionary = [NSMutableDictionary new];
                    if (parseError) {
                        dictionary[NSUnderlyingErrorKey] = parseError;
                    }
                    NSError *error = [NSError errorWithDomain:SimpleAuthErrorDomain code:SimpleAuthErrorInvalidData userInfo:dictionary];
                    [subscriber sendNext:error];
                }
            }
            else {
                NSMutableDictionary *dictionary = [NSMutableDictionary new];
                if (connectionError) {
                    dictionary[NSUnderlyingErrorKey] = connectionError;
                }
                dictionary[SimpleAuthErrorStatusCodeKey] = @(statusCode);
                NSError *error = [NSError errorWithDomain:SimpleAuthErrorDomain code:SimpleAuthErrorNetwork userInfo:dictionary];
                [subscriber sendError:error];
            }
        }];
        return nil;
    }];
}

- (NSDictionary *)responseDictionaryWithSystemAccount:(ACAccount *)systemAccount remoteAccount:(NSDictionary *)remoteAccount {
    return @{
        @"provider": [[self class] type],
        @"uid": remoteAccount[@"id"],
        @"credentials": [self credentialsDictionaryWithSystemAccount:systemAccount remoteAccount:remoteAccount],
        @"extra": [self extraDictionaryWithSystemAccount:systemAccount remoteAccount:remoteAccount],
        @"info": [self infoDictionaryWithSystemAccount:systemAccount remoteAccount:remoteAccount]
    };
}

- (NSDictionary *)credentialsDictionaryWithSystemAccount:(ACAccount *)systemAccount remoteAccount:(NSDictionary *)remoteAccount {
    return @{
        @"token": systemAccount.credential.oauthToken
    };
}

- (NSDictionary *)extraDictionaryWithSystemAccount:(ACAccount *)systemAccount remoteAccount:(NSDictionary *)remoteAccount {
    return @{
        @"raw_info": remoteAccount,
        @"account": systemAccount
    };
}

- (NSDictionary *)infoDictionaryWithSystemAccount:(ACAccount *)systemAccount remoteAccount:(NSDictionary *)remoteAccount {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];

    dictionary[@"name"] = remoteAccount[@"name"];
    dictionary[@"first_name"] = remoteAccount[@"first_name"];
    dictionary[@"last_name"] = remoteAccount[@"last_name"];
    dictionary[@"verified"] = remoteAccount[@"verified"] ?: @NO;
    
    id email = remoteAccount[@"email"];
    if (email) {
        dictionary[@"email"] = email;
    }
    
    id location = remoteAccount[@"location"][@"name"];
    if (location) {
        dictionary[@"location"] = location;
    }
    
    dictionary[@"urls"] = @{
        @"Facebook": remoteAccount[@"link"]
    };
    
    NSString *avatar = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", remoteAccount[@"id"]];
    dictionary[@"image"] = avatar;
    
    return dictionary;
}

@end
