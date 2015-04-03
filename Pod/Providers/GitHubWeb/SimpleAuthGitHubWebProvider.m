//
//  SimpleAuthGitHubWebProvider.m
//  SimpleAuth
//
//  Created by dkhamsing on 3/26/15.
//  Copyright (c) 2015 dkhamsing. All rights reserved.
//

#import "SimpleAuthGitHubWebProvider.h"
#import "SimpleAuthGitHubWebLoginViewController.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import "UIViewController+SimpleAuthAdditions.h"

@implementation SimpleAuthGitHubWebProvider

#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"github-web";
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
    dictionary[@"scope"] = @"";
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
            SimpleAuthGitHubWebLoginViewController *login = [[SimpleAuthGitHubWebLoginViewController alloc] initWithOptions:self.options];
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
        
        // Build request
        NSDictionary *parameters = @{
                                     @"code" : code,
                                     @"client_id" : self.options[@"client_id"],
                                     @"client_secret" : self.options[@"client_secret"],
                                     @"grant_type" : @"authorization_code"
                                     };        
        
        NSError *error;
        NSData *requestData = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:&error];
        if (error) {
            [subscriber sendError:error];
        }
        
        NSURL *URL = [NSURL URLWithString:@"https://github.com/login/oauth/access_token"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"%d", [requestData length]] forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody: requestData];
        
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
                               @"https://api.github.com/user?%@",
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
        @"scope": accessToken[@"scope"],
    };
    
    // User ID
    dictionary[@"id"] = account[@"id"];
    
    // Raw response
    dictionary[@"extra"] = @{
        @"raw_info" : account
    };
    
    // User info, more at https://developer.github.com/v3/users/
    NSMutableDictionary *user = [NSMutableDictionary new];
    user[@"login"] = account[@"login"];
    user[@"created_at"] = account[@"created_at"];
    dictionary[@"info"] = user;
    
    return dictionary;
}

@end
