//
//  SimpleAuthTwitterProvider.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013-2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthTwitterProvider.h"
#import "ACAccountStore+SimpleAuth.h"
#import "SimpleAuthUtilities.h"

#import <cocoa-oauth/GCOAuth.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
@import Social;

@implementation SimpleAuthTwitterProvider

#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"twitter";
}

- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion {
    [[[self systemAccount]
     flattenMap:^(ACAccount *account) {
         NSArray *signals = @[
             [RACSignal return:account],
             [self remoteAccountWithSystemAccount:account],
             [self accessTokenWithSystemAccount:account]
         ];
         return [self rac_liftSelector:@selector(responseDictionaryWithSystemAccount:remoteAccount:accessToken:) withSignalsFromArray:signals];
     }]
     subscribeNext:^(NSDictionary *response) {
         completion(response, nil);
     }
     error:^(NSError *error) {
         completion(nil, error);
     }];
}


#pragma mark - Private

- (RACSignal *)allSystemAccounts {
    return [ACAccountStore SimpleAuth_accountsWithTypeIdentifier:ACAccountTypeIdentifierTwitter options:nil];
}

- (RACSignal *)systemAccount {
    return [[self allSystemAccounts] flattenMap:^RACStream *(NSArray *accounts) {
        if ([accounts count] == 1) {
            ACAccount *account = [accounts lastObject];
            return [RACSignal return:account];
        }
        else {
            return [self systemAccountFromAccounts:accounts];
        }
    }];
}

- (RACSignal *)systemAccountFromAccounts:(NSArray *)accounts {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (NSClassFromString(@"UIAlertController")) {
                UIAlertController *controller = [UIAlertController alertControllerWithTitle:SimpleAuthLocalizedString(@"CHOOSE_ACCOUNT") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
                for (ACAccount *account in accounts) {
                    NSString *title = [NSString stringWithFormat:@"@%@", account.username];
                    [controller addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                        [subscriber sendNext:account];
                        [subscriber sendCompleted];
                    }]];
                }
                [controller addAction:[UIAlertAction actionWithTitle:SimpleAuthLocalizedString(@"CANCEL") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    NSError *error = [NSError errorWithDomain:SimpleAuthErrorDomain code:SimpleAuthErrorUserCancelled userInfo:nil];
                    [subscriber sendError:error];
                }]];
                [self presentAlertController:controller];
            }
            else {
                UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:SimpleAuthLocalizedString(@"CHOOSE_ACCOUNT") delegate:nil cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
                sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
                for (ACAccount *account in accounts) {
                    NSString *title = [NSString stringWithFormat:@"@%@", account.username];
                    [sheet addButtonWithTitle:title];
                }
                NSInteger cancelButtonIndex = sheet.cancelButtonIndex = [sheet addButtonWithTitle:SimpleAuthLocalizedString(@"CANCEL")];
                [[sheet rac_buttonClickedSignal] subscribeNext:^(NSNumber *number) {
                    NSInteger buttonIndex = [number integerValue];
                    if (buttonIndex == cancelButtonIndex) {
                        NSError *error = [NSError errorWithDomain:SimpleAuthErrorDomain code:SimpleAuthErrorUserCancelled userInfo:nil];
                        [subscriber sendError:error];
                    }
                    else {
                        ACAccount *account = accounts[buttonIndex];
                        [subscriber sendNext:account];
                        [subscriber sendCompleted];
                    }
                }];
                [self presentActionSheet:sheet];
            }
        });
        return nil;
    }];
}

- (RACSignal *)reverseAuthRequestToken {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSDictionary *parameters = @{ @"x_auth_mode" : @"reverse_auth" };
        NSURLRequest *request = [GCOAuth
                                 URLRequestForPath:@"/oauth/request_token"
                                 POSTParameters:parameters
                                 scheme:@"https"
                                 host:@"api.twitter.com"
                                 consumerKey:self.options[@"consumer_key"]
                                 consumerSecret:self.options[@"consumer_secret"]
                                 accessToken:nil
                                 tokenSecret:nil];
        [NSURLConnection sendAsynchronousRequest:request queue:self.operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
             NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 99)];
             NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
             if ([indexSet containsIndex:statusCode] && data) {
                 NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                 [subscriber sendNext:string];
                 [subscriber sendCompleted];
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

- (RACSignal *)accessTokenWithSystemAccount:(ACAccount *)account {
    return [[self reverseAuthRequestToken] flattenMap:^(NSString *token) {
        return [self accessTokenWithReverseAuthRequestToken:token account:account];
    }];
}

- (RACSignal *)remoteAccountWithSystemAccount:(ACAccount *)account {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSURL *URL = [NSURL URLWithString:@"https://api.twitter.com/1.1/account/verify_credentials.json"];
        SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:URL parameters:nil];
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

- (RACSignal *)accessTokenWithReverseAuthRequestToken:(NSString *)token account:(ACAccount *)account {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSURL *URL = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
        NSDictionary *parameters = @{
            @"x_reverse_auth_parameters" : token,
            @"x_reverse_auth_target" : self.options[@"consumer_key"]
        };
        SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:URL parameters:parameters];
        request.account = account;
        [request performRequestWithHandler:^(NSData *data, NSHTTPURLResponse *response, NSError *connectionError) {
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 99)];
            NSInteger statusCode = [response statusCode];
            if ([indexSet containsIndex:statusCode] && data) {
                NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSDictionary *dictionary = [CMDQueryStringSerialization dictionaryWithQueryString:string];
                [subscriber sendNext:dictionary];
                [subscriber sendCompleted];
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

- (NSDictionary *)responseDictionaryWithSystemAccount:(ACAccount *)systemAccount remoteAccount:(NSDictionary *)remoteAccount accessToken:(NSDictionary *)accessToken {
    return @{
        @"provider": [[self class] type],
        @"uid": remoteAccount[@"id"],
        @"credentials": [self credentialsDictionaryWithSystemAccount:systemAccount remoteAccount:remoteAccount accessToken:accessToken],
        @"extra": [self extraDictionaryWithSystemAccount:systemAccount remoteAccount:remoteAccount accessToken:accessToken],
        @"info": [self infoDictionaryWithSystemAccount:systemAccount remoteAccount:remoteAccount accessToken:accessToken]
    };
}

- (NSDictionary *)credentialsDictionaryWithSystemAccount:(ACAccount *)systemAccount remoteAccount:(NSDictionary *)remoteAccount accessToken:(NSDictionary *)accessToken {
    return @{
        @"token" : accessToken[@"oauth_token"],
        @"secret" : accessToken[@"oauth_token_secret"]
    };
}

- (NSDictionary *)extraDictionaryWithSystemAccount:(ACAccount *)systemAccount remoteAccount:(NSDictionary *)remoteAccount accessToken:(NSDictionary *)accessToken {
    return @{
        @"raw_info" : remoteAccount,
        @"account" : systemAccount
    };
}

- (NSDictionary *)infoDictionaryWithSystemAccount:(ACAccount *)systemAccount remoteAccount:(NSDictionary *)remoteAccount accessToken:(NSDictionary *)accessToken {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    
    // Basic info
    dictionary[@"nickname"] = remoteAccount[@"screen_name"];
    dictionary[@"name"] = remoteAccount[@"name"];
    dictionary[@"location"] = remoteAccount[@"location"];
    dictionary[@"description"] = remoteAccount[@"description"];
    
    // Avatar
    NSString *avatar = remoteAccount[@"profile_image_url_https"];
    avatar = [avatar stringByReplacingOccurrencesOfString:@"_normal" withString:@""];
    dictionary[@"image"] = avatar;
    
    // URLs
    NSString *profile = remoteAccount[@"screen_name"];
    profile = [NSString stringWithFormat:@"https://twitter.com/%@", profile];
    dictionary[@"urls"] = @{
        @"Twitter": profile,
        @"Website": remoteAccount[@"url"]
    };
    
    return dictionary;
}

@end
