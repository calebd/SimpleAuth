//
//  SimpleAuthTwitterProvider.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013-2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthTwitterProvider.h"

#import "UIWindow+SimpleAuthAdditions.h"
#import "ACAccountStore+SimpleAuth.h"
#import <cocoa-oauth/GCOAuth.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@implementation SimpleAuthTwitterProvider

#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"twitter";
}


+ (NSDictionary *)defaultOptions {
    void (^actionSheetBlock) (UIActionSheet *) = ^(UIActionSheet *sheet) {
        UIWindow *window = [UIWindow SimpleAuth_mainWindow];
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
    [zipSignal
     subscribeNext:^(NSDictionary *dictionary) {
         completion(dictionary, nil);
     }
     error:^(NSError *error) {
         completion(nil, error);
     }];
}


- (void)loadSystemAccount:(SimpleAuthSystemAccountHandler)completion {
    [[self systemAccount]
     subscribeNext:^(ACAccount *account) {
         completion(account, nil);
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
            SimpleAuthInterfaceHandler block = self.options[SimpleAuthPresentInterfaceBlockKey];
            block(sheet);
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
        [NSURLConnection sendAsynchronousRequest:request queue:self.operationQueue
         completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
             NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 99)];
             NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
             if ([indexSet containsIndex:statusCode] && data) {
                 NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                 [subscriber sendNext:string];
                 [subscriber sendCompleted];
             }
             else {
                 [subscriber sendError:connectionError];
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
                    [subscriber sendNext:parseError];
                }
            }
            else {
                [subscriber sendError:connectionError];
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
                [subscriber sendError:connectionError];
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
