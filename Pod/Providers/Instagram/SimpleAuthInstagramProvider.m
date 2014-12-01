//
//  SimpleAuthInstagramProvider.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/7/13.
//  Copyright (c) 2013-2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthInstagramProvider.h"
#import "SimpleAuthInstagramLoginViewController.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

@implementation SimpleAuthInstagramProvider

#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"instagram";
}

- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion {
    [[[self accessToken]
     flattenMap:^RACStream *(NSString *response) {
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
            SimpleAuthInstagramLoginViewController *controller = [[SimpleAuthInstagramLoginViewController alloc] initWithOptions:self.options];
            controller.completion = ^(UIViewController *controller, NSURL *URL, NSError *error) {
                [controller dismissViewControllerAnimated:YES completion:nil];
                
                // Parse URL
                NSString *fragment = [URL fragment];
                NSDictionary *dictionary = [CMDQueryStringSerialization dictionaryWithQueryString:fragment];
                NSString *token = dictionary[@"access_token"];
                
                // Check for error
                if (![token length]) {
                    [subscriber sendError:error];
                    return;
                }
                
                // Send completion
                [subscriber sendNext:token];
                [subscriber sendCompleted];
            };
            [self presentLoginViewController:controller];
        });
        return nil;
    }];
}

- (RACSignal *)accountWithAccessToken:(NSString *)accessToken {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSDictionary *parameters = @{ @"access_token" : accessToken };
        NSString *queryString = [CMDQueryStringSerialization queryStringWithDictionary:parameters];
        NSString *URLString = [NSString stringWithFormat:@"https://api.instagram.com/v1/users/self?%@", queryString];
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


#pragma mark - Private

- (NSDictionary *)responseDictionaryWithRemoteAccount:(NSDictionary *)remoteAccount accessToken:(NSString *)accessToken {
    remoteAccount = remoteAccount[@"data"];
    return @{
        @"provider": [[self class] type],
        @"credentials": [self credentialsDictionaryWithRemoteAccount:remoteAccount accessToken:accessToken],
        @"uid": remoteAccount[@"id"],
        @"extra": remoteAccount,
        @"info": [self infoDictionaryWithRemoteAccount:remoteAccount accessToken:accessToken]
    };
}

- (NSDictionary *)credentialsDictionaryWithRemoteAccount:(NSDictionary *)remoteAccount accessToken:(NSString *)accessToken {
    return @{
        @"token" : accessToken
    };
}

- (NSDictionary *)infoDictionaryWithRemoteAccount:(NSDictionary *)remoteAccount accessToken:(NSString *)accessToken {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    
    id nickname = remoteAccount[@"username"];
    if (nickname) {
        dictionary[@"nickname"] = nickname;
    }
    
    id name = remoteAccount[@"full_name"];
    if (name) {
        dictionary[@"name"] = name;
    }
    
    id email = remoteAccount[@"email"];
    if (email) {
        dictionary[@"email"] = email;
    }
    
    id image = remoteAccount[@"profile_picture"];
    if (image) {
        dictionary[@"image"] = image;
    }
    
    id bio = remoteAccount[@"bio"];
    if (bio) {
        dictionary[@"bio"] = bio;
    }
    
    id website = remoteAccount[@"website"];
    if (website) {
        dictionary[@"website"] = website;
    }
    
    return dictionary;
}

@end
