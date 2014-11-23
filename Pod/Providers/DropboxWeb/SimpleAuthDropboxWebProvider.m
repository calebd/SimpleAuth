//
//  SimpleAuthDropboxWebProvider.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 1/23/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthDropboxWebProvider.h"
#import "SimpleAuthDropboxWebLoginViewController.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

@implementation SimpleAuthDropboxWebProvider

#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"dropbox-web";
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
            SimpleAuthDropboxWebLoginViewController *controller = [[SimpleAuthDropboxWebLoginViewController alloc] initWithOptions:self.options];
            controller.completion = ^(UIViewController *controller, NSURL *URL, NSError *error) {
                [controller dismissViewControllerAnimated:YES completion:nil];
                
                // Parse URL
                NSString *fragment = [URL fragment];
                NSDictionary *dictionary = [CMDQueryStringSerialization dictionaryWithQueryString:fragment];
                id token = dictionary[@"access_token"];
                
                // Check for error
                if (!token) {
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
        NSString *URLString = [NSString stringWithFormat:@"https://api.dropbox.com/1/account/info?%@", queryString];
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
                     NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
                     if (parseError) {
                         dictionary[NSUnderlyingErrorKey] = parseError;
                     }
                     NSError *error = [NSError errorWithDomain:SimpleAuthErrorDomain code:SimpleAuthErrorInvalidData userInfo:dictionary];
                     [subscriber sendNext:error];
                 }
             }
             else {
                 NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
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
        @"uid": remoteAccount[@"uid"],
        @"credentials": [self credentialsDictionaryWithRemoteAccount:remoteAccount accessToken:accessToken],
        @"extra": remoteAccount,
        @"info": [self infoDictionaryWithRemoteAccount:remoteAccount accessToken:accessToken]
    };
}

- (NSDictionary *)credentialsDictionaryWithRemoteAccount:(NSDictionary *)remoteAccount accessToken:(NSDictionary *)accessToken {
    return @{
        @"token" : accessToken[@"access_token"],
        @"type" : accessToken[@"token_type"]
    };
}

- (NSDictionary *)infoDictionaryWithRemoteAccount:(NSDictionary *)remoteAccount accessToken:(NSDictionary *)accessToken {
    return @{
        @"email": remoteAccount[@"email"],
        @"name": remoteAccount[@"display_name"]
    };
}

@end
