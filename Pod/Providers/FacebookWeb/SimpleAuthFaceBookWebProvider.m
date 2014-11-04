//
//  SimpleAuthFaceBookWebProvider.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 1/22/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthFaceBookWebProvider.h"
#import "SimpleAuthFacebookWebLoginViewController.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

@implementation SimpleAuthFaceBookWebProvider

#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"facebook-web";
}

+ (NSDictionary *)defaultOptions {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[super defaultOptions]];
    dictionary[SimpleAuthRedirectURIKey] = @"https://www.facebook.com/connect/login_success.html";
    dictionary[@"permissions"] = @[ @"email" ];
    return dictionary;
}

- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion {
    [[[self accessToken]
     flattenMap:^(NSDictionary *response) {
         NSArray *signals = @[
             [self accountWithAccessToken:response],
             [RACSignal return:response]
         ];
         return [self rac_liftSelector:@selector(responseDictionaryWithRemoteAccount:accessToken:) withSignalsFromArray:signals];
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
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        dispatch_async(dispatch_get_main_queue(), ^{
            SimpleAuthFacebookWebLoginViewController *controller = [[SimpleAuthFacebookWebLoginViewController alloc] initWithOptions:self.options];
            controller.completion = ^(UIViewController *controller, NSURL *URL, NSError *error) {
                [controller dismissViewControllerAnimated:YES completion:nil];
                
                // Parse URL
                NSString *fragment = [URL fragment];
                NSDictionary *dictionary = [CMDQueryStringSerialization dictionaryWithQueryString:fragment];
                id token = dictionary[@"access_token"];
                id expiration = dictionary[@"expires_in"];
                
                // Check for error
                if (!token || !expiration) {
                    [subscriber sendError:error];
                    return;
                }
                
                // Send completion
                [subscriber sendNext:dictionary];
                [subscriber sendCompleted];
            };
            [self presentLoginViewController:controller];
        });
        return nil;
    }];
}

- (RACSignal *)accountWithAccessToken:(NSDictionary *)accessToken {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSDictionary *parameters = @{ @"access_token" : accessToken[@"access_token"] };
        NSString *queryString = [CMDQueryStringSerialization queryStringWithDictionary:parameters];
        NSString *URLString = [NSString stringWithFormat:@"https://graph.facebook.com/me?%@", queryString];
        NSURL *URL = [NSURL URLWithString:URLString];
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        [NSURLConnection sendAsynchronousRequest:request queue:self.operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
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

- (NSDictionary *)responseDictionaryWithRemoteAccount:(NSDictionary *)remoteAccount accessToken:(NSDictionary *)accessToken {
    return @{
        @"provider": [[self class] type],
        @"credentials": [self credentialsDictionaryWithRemoteAccount:remoteAccount accessToken:accessToken],
        @"uid": remoteAccount[@"id"],
        @"extra": remoteAccount,
        @"info": [self infoDictionaryWithRemoteAccount:remoteAccount accessToken:accessToken]
    };
}

- (NSDictionary *)credentialsDictionaryWithRemoteAccount:(NSDictionary *)remoteAccount accessToken:(NSDictionary *)accessToken {
    NSTimeInterval expiresAtInterval = [accessToken[@"expires_in"] doubleValue];
    NSDate *expiresAtDate = [NSDate dateWithTimeIntervalSinceNow:expiresAtInterval];
    return @{
        @"token" : accessToken[@"access_token"],
        @"expires_at" : expiresAtDate
    };
}

- (NSDictionary *)extraDictionaryWithRemoteAccount:(NSDictionary *)remoteAccount accessToken:(NSDictionary *)accessToken {
    return @{
        @"raw_info": remoteAccount,
    };
}

- (NSDictionary *)infoDictionaryWithRemoteAccount:(NSDictionary *)remoteAccount accessToken:(NSDictionary *)accessToken {
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
