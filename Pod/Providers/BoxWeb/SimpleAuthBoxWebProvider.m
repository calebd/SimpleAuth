//
//  SimpleAuthBoxWebProvider.m
//  SimpleAuth
//
//  Created by dkhamsing on 3/26/15.
//  Copyright (c) 2015 dkhamsing. All rights reserved.
//

#import "SimpleAuthBoxWebProvider.h"
#import "SimpleAuthBoxWebLoginViewController.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import "UIViewController+SimpleAuthAdditions.h"

@implementation SimpleAuthBoxWebProvider

#pragma mark - Initializers

- (instancetype)initWithOptions:(NSDictionary *)options {
    NSMutableDictionary *mutableOptions = [NSMutableDictionary dictionaryWithDictionary:options];
    mutableOptions[SimpleAuthRedirectURIKey] = [NSString stringWithFormat:@"boxsdk-%@://boxsdkoauth2redirect", options[@"client_id"]];
    self = [super initWithOptions:[mutableOptions copy]];
    return self;
}


#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"box-web";
}


+ (NSDictionary *)defaultOptions {
    
    // Default present block
    SimpleAuthInterfaceHandler presentBlock = ^(UIViewController *controller) {
        UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:controller];
        navigation.modalPresentationStyle = UIModalPresentationFormSheet;
        UIViewController *presented = [UIViewController SimpleAuth_presentedViewController];
        [presented presentViewController:navigation animated:YES completion:nil];
    };
    
    // Default dismiss block
    SimpleAuthInterfaceHandler dismissBlock = ^(id controller) {
        [controller dismissViewControllerAnimated:YES completion:nil];
    };
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[super defaultOptions]];
    dictionary[SimpleAuthPresentInterfaceBlockKey] = presentBlock;
    dictionary[SimpleAuthDismissInterfaceBlockKey] = dismissBlock;
    return dictionary;
}


- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion {
    [[[self accessToken]
        flattenMap:^(NSDictionary *response) {
            NSArray *signals = @[
                [self accountWithAccessToken:response],
                [RACSignal return:response]
            ];
            return [self rac_liftSelector:@selector(dictionaryWithAccount:accessToken:) withSignalsFromArray:signals];
        }]
        subscribeNext:^(NSDictionary *response) {
            completion(response, nil);
        }
        error:^(NSError *error) {
            completion(nil, error);
        }];
}


#pragma mark - Private

- (RACSignal *)authorizationCode {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        dispatch_async(dispatch_get_main_queue(), ^{                    
            SimpleAuthBoxWebLoginViewController *login = [[SimpleAuthBoxWebLoginViewController alloc] initWithOptions:self.options];
            login.completion = ^(UIViewController *login, NSURL *URL, NSError *error) {
                SimpleAuthInterfaceHandler dismissBlock = self.options[SimpleAuthDismissInterfaceBlockKey];
                dismissBlock(login);
                
                // Parse URL
                NSString *fragment = [URL query];
                NSDictionary *dictionary = [CMDQueryStringSerialization dictionaryWithQueryString:fragment];
                NSString *code = dictionary[@"code"];
                
                // Check for error
                if (![code length]) {
                    [subscriber sendError:error];
                    return;
                }
                
                // Send completion
                [subscriber sendNext:code];
                [subscriber sendCompleted];
            };
            
            SimpleAuthInterfaceHandler block = self.options[SimpleAuthPresentInterfaceBlockKey];
            block(login);
        });
        return nil;
    }];
}


- (RACSignal *)accessTokenWithAuthorizationCode:(NSString *)code {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        // Build parameters
        NSDictionary *parameters = @{
            @"code" : code,
            @"client_id" : self.options[@"client_id"],
            @"client_secret" : self.options[@"client_secret"],
            @"redirect_uri" : self.options[SimpleAuthRedirectURIKey],
            @"grant_type" : @"authorization_code"
        };

        // Build request
        NSString *query = [CMDQueryStringSerialization queryStringWithDictionary:parameters];
        NSURL *URL = [NSURL URLWithString:@"https://api.box.com/oauth2/token"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:[query dataUsingEncoding:NSUTF8StringEncoding]];
        
        // Run request
        [NSURLConnection sendAsynchronousRequest:request queue:self.operationQueue
            completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 99)];
                NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
                if ([indexSet containsIndex:statusCode] && data) {
                    NSError *parseError = nil;
                    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&parseError];
                    if (dictionary) {
                        [subscriber sendNext:dictionary];
                        [subscriber sendCompleted];
                    }
                    else {
                        [subscriber sendError:parseError];
                    }
                }
                else {
                    [subscriber sendError:connectionError];
                }
            }];
        return nil;
    }];
}


- (RACSignal *)accessToken {
    return [[self authorizationCode] flattenMap:^(id responseObject) {
        return [self accessTokenWithAuthorizationCode:responseObject];
    }];
}


- (RACSignal *)accountWithAccessToken:(NSDictionary *)accessToken {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSDictionary *parameters = @{ @"access_token" : accessToken[@"access_token"] };
        NSString *URLString = [NSString stringWithFormat:
                               @"https://api.box.com/2.0/users/me?%@",
                               [CMDQueryStringSerialization queryStringWithDictionary:parameters]];
        NSURL *URL = [NSURL URLWithString:URLString];
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        [NSURLConnection sendAsynchronousRequest:request queue:self.operationQueue
            completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 99)];
                NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
                if ([indexSet containsIndex:statusCode] && data) {
                    NSError *parseError = nil;
                    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&parseError];
                    if (dictionary) {
                        [subscriber sendNext:dictionary];
                        [subscriber sendCompleted];
                    }
                    else {
                        [subscriber sendError:parseError];
                    }
                }
                else {
                    [subscriber sendError:connectionError];
                }
            }];
        return nil;
    }];
}


- (NSDictionary *)dictionaryWithAccount:(NSDictionary *)account accessToken:(NSDictionary *)accessToken {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    
    // Provider
    dictionary[@"provider"] = [[self class] type];
    
    // Credentials
    dictionary[@"credentials"] = @{
        @"token" : accessToken[@"access_token"],
        @"type" : accessToken[@"token_type"],
        @"expires_in": accessToken[@"expires_in"],
        @"refresh_token": accessToken[@"refresh_token"],
    };
    
    // User ID
    dictionary[@"id"] = account[@"id"];
    
    // Raw response
    dictionary[@"extra"] = @{
        @"raw_info" : account
    };
    
    // User info
    NSMutableDictionary *user = [NSMutableDictionary new];
    user[@"login"] = account[@"login"];
    user[@"name"] = account[@"name"];
    dictionary[@"info"] = user;
    
    return dictionary;
}

@end
