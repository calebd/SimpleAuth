//
//  SimpleAuthFoursquareWebProvider.m
//  SimpleAuth
//
//  Created by Julien Seren-Rosso on 23/01/2014.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthFoursquareWebProvider.h"
#import "SimpleAuthFoursquareWebLoginViewController.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import "UIViewController+SimpleAuthAdditions.h"

@implementation SimpleAuthFoursquareWebProvider

#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"foursquare-web";
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
    
    NSMutableDictionary *options = [NSMutableDictionary dictionaryWithDictionary:[super defaultOptions]];
    options[SimpleAuthPresentInterfaceBlockKey] = presentBlock;
    options[SimpleAuthDismissInterfaceBlockKey] = dismissBlock;
    return options;
}


- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion {
    [[[self accessToken]
     flattenMap:^RACStream *(NSString *response) {
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
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        dispatch_async(dispatch_get_main_queue(), ^{
            SimpleAuthFoursquareWebLoginViewController *login = [[SimpleAuthFoursquareWebLoginViewController alloc] initWithOptions:self.options];
            login.completion = ^(UIViewController *login, NSURL *URL, NSError *error) {
                SimpleAuthInterfaceHandler dismissBlock = self.options[SimpleAuthDismissInterfaceBlockKey];
                dismissBlock(login);
                
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
            
            SimpleAuthInterfaceHandler block = self.options[SimpleAuthPresentInterfaceBlockKey];
            block(login);
        });
        return nil;
    }];
}


- (RACSignal *)accountWithAccessToken:(NSString *)accessToken {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSDictionary *parameters = @{ @"oauth_token" : accessToken };
        NSString *query = [CMDQueryStringSerialization queryStringWithDictionary:parameters];
        NSString *URLString = [NSString stringWithFormat:@"https://api.foursquare.com/v2/users/self?v=20140210&%@", query];
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


- (NSDictionary *)dictionaryWithAccount:(NSDictionary *)account accessToken:(NSString *)accessToken {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    NSDictionary *userData = account[@"response"][@"user"];
    
    // Provider
    dictionary[@"provider"] = [[self class] type];
    
    // Credentials
    dictionary[@"credentials"] = @{
                                   @"token" : accessToken
                                   };
    
    // User ID
    dictionary[@"uid"] = userData[@"id"];
    
    // Raw response
    dictionary[@"extra"] = @{
                             @"raw_info" : userData
                             };
    
    // User info
    NSMutableDictionary *user = [NSMutableDictionary new];
    if (userData[@"contact"][@"email"]) {
        user[@"email"] = userData[@"contact"][@"email"];
    }
    
    if (userData[@"firstName"]) {
        user[@"first_name"] = userData[@"firstName"];
    }
    
    if (userData[@"lastName"]) {
        user[@"last_name"] = userData[@"lastName"];
    }
    
    user[@"name"] = [NSString stringWithFormat:@"%@ %@", user[@"first_name"], user[@"last_name"]];
    
    user[@"gender"] = userData[@"gender"];
    
    if ([userData[@"photo"] isKindOfClass:NSDictionary.class]) {
        user[@"image"] = [NSString stringWithFormat:@"%@500x500%@", userData[@"photo"][@"prefix"], userData[@"photo"][@"suffix"]];
    } else if ([userData[@"photo"] isKindOfClass:NSString.class]) {
        user[@"image"] = userData[@"photo"];
    }
    
    if (userData[@"photo"]) {
        user[@"photo"] = userData[@"photo"];
    }
    if (userData[@"homeCity"]) {
        NSString *homecity = [[userData[@"homeCity"] componentsSeparatedByString:@","] firstObject];
        user[@"location"] = homecity;
    }
    user[@"urls"] = @{
                      @"Foursquare" : [NSString stringWithFormat:@"https://foursquare.com/user/%@", userData[@"id"]],
                      };
    dictionary[@"info"] = user;
    
    return dictionary;
}


@end
