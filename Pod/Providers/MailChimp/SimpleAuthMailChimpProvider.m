//
//  SimpleAuthMailChimpProvider.m
//  SimpleAuth
//
//  Created by Tal Kain <tal@kain.net>.
//  Based on BoxWeb's provider created by dkhamsing and FoursquareWeb's provider created by Julien Seren-Rosso
//  Copyright (c) 2015 Fire Place Inc. All rights reserved.
//

#import "SimpleAuthMailChimpProvider.h"
#import "SimpleAuthMailChimpLoginViewController.h"
#import "SimpleAuthMailChimpConstants.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import "UIViewController+SimpleAuthAdditions.h"

@implementation SimpleAuthMailChimpProvider

#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"mailchimp";
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


- (RACSignal *)accessToken {
    return [[self authorizationCode] flattenMap:^(id responseObject) {
        return [self accessTokenWithAuthorizationCode:responseObject];
    }];
}

- (RACSignal *)authorizationCode {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        dispatch_async(dispatch_get_main_queue(), ^{
            SimpleAuthMailChimpLoginViewController *login = [[SimpleAuthMailChimpLoginViewController alloc] initWithOptions:self.options];
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
        NSURL *URL = [NSURL URLWithString:MAIL_CHIMP_ACCESS_TOKEN_URI];
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

- (RACSignal *)accountWithAccessToken:(NSDictionary *)accessToken {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSURL *URL = [NSURL URLWithString:MAIL_CHIMP_META_DATA_END_POINT_URI];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
        NSString *oauthCode = [NSString stringWithFormat:@"OAuth %@", accessToken[@"access_token"]];
        [request setValue:oauthCode forHTTPHeaderField:@"Authorization"];
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
        @"type" : @"authorization_code",
        @"expires_in": accessToken[@"expires_in"],
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
