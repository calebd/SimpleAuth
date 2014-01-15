//
//  SimpleAuthTwitterProvider.m
//  SimpleAuthTwitter
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 Seesaw Decisions Corporation. All rights reserved.
//

#import "SimpleAuthTwitterProvider.h"

#import "UIWindow+SimpleAuthAdditions.h"

#import <cocoa-oauth/GCOAuth.h>
#import <SAMCategories/NSDictionary+SAMAdditions.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface SimpleAuthTwitterProvider () <UIActionSheetDelegate>

@end

@implementation SimpleAuthTwitterProvider {
    NSArray *_accounts;
    SimpleAuthSystemAccountHandler _systemAccountCompletion;
}

#pragma mark - NSObject

+ (void)load {
    @autoreleasepool {
        [SimpleAuth registerProviderClass:self];
    }
}


#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"twitter";
}


+ (NSDictionary *)defaultOptions {
    void (^actionSheetBlock) (UIActionSheet *) = ^(UIActionSheet *sheet) {
        UIWindow *window = [UIWindow sa_mainWindow];
        [sheet showInView:window];
    };
    
    NSMutableDictionary *options = [[super defaultOptions] mutableCopy];
    options[@"action_sheet_block"] = actionSheetBlock;
    
    return options;
}


#pragma mark - SimpleAuthSystemProvider

- (void)authorizeWithSystemAccount:(ACAccount *)account completion:(SimpleAuthRequestHandler)completion {
    RACSignal *accountSignal = [self twitterAccountWithAccount:account];
    RACSignal *accessTokenSignal = [self accessTokenWithAccount:account];
    RACSignal *zipSignal = [RACSignal zip:@[ accountSignal, accessTokenSignal ] reduce:^(NSDictionary *accountDictionary, NSDictionary *accessTokenDictionary) {
        return [self responseWithAccount:account accountDictionary:accountDictionary accessTokenDictionary:accessTokenDictionary];
    }];
    [[zipSignal deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(NSDictionary *dictionary) {
         completion(dictionary, nil);
     }
     error:^(NSError *error) {
         completion(nil, error);
     }];
}


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
                else if (numberOfAccounts == 1) {
                    completion([accounts lastObject], nil);
                }
                else {
                    _systemAccountCompletion = completion;
                    _accounts = accounts;
                    
                    UIActionSheet *sheet = [UIActionSheet new];
                    for (ACAccount *account in accounts) {
                        NSString *title = [NSString stringWithFormat:@"@%@", account.username];
                        [sheet addButtonWithTitle:title];
                    }
                    sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
                    sheet.delegate = self;
                    sheet.cancelButtonIndex = [sheet addButtonWithTitle:NSLocalizedString(@"GENERAL_CANCEL", nil)];
                    
                    void (^block) (UIActionSheet *) = self.options[@"action_sheet_block"];
                    block(sheet);
                }
            }
            else {
                completion(nil, error ?: [[NSError alloc] initWithDomain:ACErrorDomain code:ACErrorPermissionDenied userInfo:nil]);
            }
        });
    }];
}


#pragma mark - Public

- (RACSignal *)requestTokenWithParameters:(NSDictionary *)parameters {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSURLRequest *request = [GCOAuth
         URLRequestForPath:@"/oauth/request_token"
         POSTParameters:parameters
         scheme:@"https"
         host:@"api.twitter.com"
         consumerKey:self.options[@"consumer_key"]
         consumerSecret:self.options[@"consumer_secret"]
         accessToken:nil
         tokenSecret:nil];
        [NSURLConnection
         sendAsynchronousRequest:request
         queue:[NSOperationQueue mainQueue]
         completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
             NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
             if (statusCode == 200 && data) {
                 NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                 [subscriber sendNext:string];
             }
             else {
                 [subscriber sendError:error];
             }
             [subscriber sendCompleted];
         }];
        return nil;
    }];
}


- (RACSignal *)accessTokenWithAccount:(ACAccount *)account {
    return [[self reverseAuthRequestToken] flattenMap:^(NSString *token) {
        return [self accessTokenWithReverseAuthRequestToken:token account:account];
    }];
}


- (RACSignal *)twitterAccountWithAccount:(ACAccount *)account {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSURL *URL = [NSURL URLWithString:@"https://api.twitter.com/1.1/account/verify_credentials.json"];
        SLRequest *request = [SLRequest
         requestForServiceType:SLServiceTypeTwitter
         requestMethod:SLRequestMethodGET
         URL:URL
         parameters:nil];
        request.account = account;
        [request performRequestWithHandler:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
            NSInteger statusCode = [response statusCode];
            if (statusCode == 200 && data) {
                NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                [subscriber sendNext:dictionary];
            }
            else {
                [subscriber sendError:error];
            }
            [subscriber sendCompleted];
        }];
        return nil;
    }];
}


#pragma mark - Private

- (RACSignal *)reverseAuthRequestToken {
    return [self requestTokenWithParameters:@{
        @"x_auth_mode" : @"reverse_auth"
    }];
}


- (RACSignal *)accessTokenWithReverseAuthRequestToken:(NSString *)token account:(ACAccount *)account {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSURL *URL = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
        NSDictionary *parameters = @{
            @"x_reverse_auth_parameters" : token,
            @"x_reverse_auth_target" : self.options[@"consumer_key"]
        };
        SLRequest *request = [SLRequest
         requestForServiceType:SLServiceTypeTwitter
         requestMethod:SLRequestMethodPOST
         URL:URL
         parameters:parameters];
        request.account = account;
        [request performRequestWithHandler:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
            NSInteger statusCode = [response statusCode];
            if (statusCode == 200 && data) {
                NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSDictionary *dictionary = [NSDictionary sam_dictionaryWithFormEncodedString:string];
                [subscriber sendNext:dictionary];
            }
            else {
                [subscriber sendError:error];
            }
            [subscriber sendCompleted];
        }];
        return nil;
    }];
}


- (NSDictionary *)responseWithAccount:(ACAccount *)account accountDictionary:(NSDictionary *)accountDictionary accessTokenDictionary:(NSDictionary *)accessToken {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    
    // Provider
    dictionary[@"provider"] = [[self class] type];
    
    // Credentials
    dictionary[@"credentials"] = @{
        @"token" : accessToken[@"oauth_token"],
        @"secret" : accessToken[@"oauth_token_secret"]
    };
    
    // User ID
    dictionary[@"uid"] = accountDictionary[@"id"];
    
    // Extra
    dictionary[@"extra"] = @{
        @"raw_info" : accountDictionary,
        @"account" : account
    };
    
    // Profile image
    NSString *avatar = accountDictionary[@"profile_image_url_https"];
    avatar = [avatar stringByReplacingOccurrencesOfString:@"_normal" withString:@""];
    
    // Profile
    NSString *profile = [NSString stringWithFormat:@"https://twitter.com/%@", accountDictionary[@"screen_name"]];
    
    // User info
    NSMutableDictionary *user = [NSMutableDictionary new];
    user[@"nickname"] = accountDictionary[@"screen_name"];
    user[@"name"] = accountDictionary[@"name"];
    user[@"location"] = accountDictionary[@"location"];
    user[@"image"] = avatar;
    user[@"description"] = accountDictionary[@"description"];
    user[@"urls"] = @{
        @"Twitter" : profile,
        @"Website" : accountDictionary[@"url"]
    };
    dictionary[@"info"] = user;
    
    return dictionary;
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        NSError *error = [NSError errorWithDomain:SimpleAuthErrorDomain code:SimpleAuthUserCancelledErrorCode userInfo:nil];
        _systemAccountCompletion(nil, error);
    }
    else {
        ACAccount *account = _accounts[buttonIndex];
        _systemAccountCompletion(account, nil);
    }
    _systemAccountCompletion = nil;
}

@end
