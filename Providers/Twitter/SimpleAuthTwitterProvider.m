//
//  SimpleAuthTwitterProvider.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 Seesaw Decisions Corporation. All rights reserved.
//

#import "SimpleAuthTwitterProvider.h"

#import "UIWindow+SimpleAuthAdditions.h"

#import <cocoa-oauth/GCOAuth.h>
#import <SAMCategories/NSDictionary+SAMAdditions.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@implementation SimpleAuthTwitterProvider

#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"twitter";
}


+ (NSDictionary *)defaultOptions {
    void (^actionSheetBlock) (UIActionSheet *) = ^(UIActionSheet *sheet) {
        UIWindow *window = [UIWindow sa_mainWindow];
        [sheet showInView:window];
    };
    
    NSMutableDictionary *options = [NSMutableDictionary dictionaryWithDictionary:[super defaultOptions]];
    options[SimpleAuthPresentInterfaceBlockKey] = actionSheetBlock;
    
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
    [[[self selectedTwitterAccount]
     deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(ACAccount *account) {
         completion(account, nil);
     }
     error:^(NSError *error) {
         completion(nil, error);
     }];
}


#pragma mark - Private

- (RACSignal *)allTwitterAccounts {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        ACAccountStore *store = [[self class] accountStore];
        ACAccountType *type = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        [store requestAccessToAccountsWithType:type options:nil completion:^(BOOL granted, NSError *error) {
            if (granted) {
                NSArray *accounts = [store accountsWithAccountType:type];
                NSUInteger numberOfAccounts = [accounts count];
                if (numberOfAccounts) {
                    [subscriber sendNext:accounts];
                    [subscriber sendCompleted];
                }
                else {
                    [subscriber sendError:(error ?: [[NSError alloc] initWithDomain:ACErrorDomain code:ACErrorAccountNotFound userInfo:nil])];
                }
            }
            else {
                [subscriber sendError:(error ?: [[NSError alloc] initWithDomain:ACErrorDomain code:ACErrorPermissionDenied userInfo:nil])];
            }
        }];
        return nil;
    }];
}


- (RACSignal *)selectedTwitterAccount {
    return [[self allTwitterAccounts] flattenMap:^RACStream *(NSArray *accounts) {
        if ([accounts count] == 1) {
            ACAccount *account = [accounts lastObject];
            return [RACSignal return:account];
        }
        else {
            return [self twitterAccountFromAccounts:accounts];
        }
    }];
}


- (RACSignal *)twitterAccountFromAccounts:(NSArray *)accounts {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIActionSheet *sheet = [UIActionSheet new];
            for (ACAccount *account in accounts) {
                NSString *title = [NSString stringWithFormat:@"@%@", account.username];
                [sheet addButtonWithTitle:title];
            }
            sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
            sheet.cancelButtonIndex = [sheet addButtonWithTitle:NSLocalizedString(@"GENERAL_CANCEL", nil)];
            
            SEL s = @selector(actionSheet:clickedButtonAtIndex:);
            Protocol *p = @protocol(UIActionSheetDelegate);
            [[sheet rac_signalForSelector:s fromProtocol:p] subscribeNext:^(RACTuple *tuple) {
                RACTupleUnpack(UIActionSheet *sheet, NSNumber *number) = tuple;
                NSInteger index = [number integerValue];
                if (index == sheet.cancelButtonIndex) {
                    NSError *error = [NSError errorWithDomain:SimpleAuthErrorDomain code:SimpleAuthUserCancelledErrorCode userInfo:nil];
                    [subscriber sendError:error];
                }
                else {
                    ACAccount *account = accounts[index];
                    [subscriber sendNext:account];
                    [subscriber sendCompleted];
                }
            }];
            
            sheet.delegate = (id)sheet;
            void (^block) (UIActionSheet *) = self.options[@"action_sheet_block"];
            block(sheet);
        });
        return nil;
    }];
}


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
                 [subscriber sendCompleted];
             }
             else {
                 [subscriber sendError:error];
             }
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
                [subscriber sendCompleted];
            }
            else {
                [subscriber sendError:error];
            }
        }];
        return nil;
    }];
}


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
                [subscriber sendCompleted];
            }
            else {
                [subscriber sendError:error];
            }
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

@end
