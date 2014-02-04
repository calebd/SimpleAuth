//
//  SimpleAuthTumblrProvider.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 1/16/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthTumblrProvider.h"
#import "SimpleAuthTumblrLoginViewController.h"

#import "UIViewController+SimpleAuthAdditions.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <cocoa-oauth/GCOAuth.h>

@implementation SimpleAuthTumblrProvider

#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"tumblr";
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
    dictionary[SimpleAuthRedirectURIKey] = @"simple-auth://tumblr.auth";
    return dictionary;
}


- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion {
    [[[[[self requestToken]
     flattenMap:^(NSDictionary *response) {
         NSArray *signals = @[  
             [RACSignal return:response],
             [self authenticateWithRequestToken:response]
         ];
         return [RACSignal zip:signals];
     }]
     flattenMap:^(RACTuple *response) {
         return [self accessTokenWithRequestToken:response.first authenticationResponse:response.second];
     }]
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

- (RACSignal *)requestToken {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSDictionary *parameters = @{ @"oauth_callback" : self.options[SimpleAuthRedirectURIKey] };
        NSURLRequest *request = [GCOAuth
                                 URLRequestForPath:@"/oauth/request_token"
                                 POSTParameters:parameters
                                 scheme:@"https"
                                 host:@"www.tumblr.com"
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


- (RACSignal *)authenticateWithRequestToken:(NSDictionary *)requestToken {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        dispatch_async(dispatch_get_main_queue(), ^{
            SimpleAuthTumblrLoginViewController *login = [[SimpleAuthTumblrLoginViewController alloc] initWithOptions:self.options requestToken:requestToken];
            
            login.completion = ^(UIViewController *controller, NSURL *URL, NSError *error) {
                SimpleAuthInterfaceHandler block = self.options[SimpleAuthDismissInterfaceBlockKey];
                block(controller);
                
                // Parse URL
                NSString *query = [URL query];
                NSDictionary *dictionary = [CMDQueryStringSerialization dictionaryWithQueryString:query];
                NSString *token = dictionary[@"oauth_token"];
                NSString *verifier = dictionary[@"oauth_verifier"];
                
                // Check for error
                if (![token length] || ![verifier length]) {
                    [subscriber sendError:error];
                    return;
                }
                
                // Send completion
                [subscriber sendNext:dictionary];
                [subscriber sendCompleted];
            };
            
            SimpleAuthInterfaceHandler block = self.options[SimpleAuthPresentInterfaceBlockKey];
            block(login);    
        });
        return nil;
    }];
}


- (RACSignal *)accessTokenWithRequestToken:(NSDictionary *)requestToken authenticationResponse:(NSDictionary *)authenticationResponse {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSDictionary *parameters = @{ @"oauth_verifier" : authenticationResponse[@"oauth_verifier"] };
        NSURLRequest *request = [GCOAuth
                                 URLRequestForPath:@"/oauth/access_token"
                                 POSTParameters:parameters
                                 scheme:@"https"
                                 host:@"www.tumblr.com"
                                 consumerKey:self.options[@"consumer_key"]
                                 consumerSecret:self.options[@"consumer_secret"]
                                 accessToken:authenticationResponse[@"oauth_token"]
                                 tokenSecret:requestToken[@"oauth_token_secret"]];
        [NSURLConnection sendAsynchronousRequest:request queue:self.operationQueue
         completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
             NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 99)];
             NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
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


- (RACSignal *)accountWithAccessToken:(NSDictionary *)accessToken {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSURLRequest *request = [GCOAuth
                                 URLRequestForPath:@"/v2/user/info"
                                 GETParameters:nil
                                 scheme:@"https"
                                 host:@"api.tumblr.com"
                                 consumerKey:self.options[@"consumer_key"]
                                 consumerSecret:self.options[@"consumer_secret"]
                                 accessToken:accessToken[@"oauth_token"]
                                 tokenSecret:accessToken[@"oauth_token_secret"]];
        [NSURLConnection
         sendAsynchronousRequest:request
         queue:self.operationQueue
         completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
             NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 99)];
             NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
             if ([indexSet containsIndex:statusCode] && data) {
                 NSError *parseError = nil;
                 NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&parseError];
                 if (dictionary) {
                     dictionary = dictionary[@"response"][@"user"];
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
        @"token" : accessToken[@"oauth_token"],
        @"secret" : accessToken[@"oauth_token_secret"]
    };
    
    // User ID
    dictionary[@"uid"] = account[@"name"];
    
    // Extra
    dictionary[@"extra"] = @{
        @"raw_info" : account,
    };
    
    // Blogs
    NSArray *blogs = account[@"blogs"];
    blogs = [[blogs.rac_sequence map:^(NSDictionary *dictionary) {
        return [dictionary dictionaryWithValuesForKeys:@[ @"name", @"url", @"title" ]];
    }] array];
    
    // Profile image
    NSString *blogURLString = blogs[0][@"url"];
    NSURL *blogURL = [NSURL URLWithString:blogURLString];
    NSString *host = [blogURL host];
    NSString *avatar = [NSString stringWithFormat:@"https://api.tumblr.com/v2/blog/%@/avatar", host];
    
    // User info
    NSMutableDictionary *user = [NSMutableDictionary new];
    user[@"nickname"] = account[@"name"];
    user[@"name"] = account[@"name"];
    user[@"blogs"] = blogs;
    user[@"image"] = avatar;
    dictionary[@"info"] = user;
    
    return dictionary;
}

@end
