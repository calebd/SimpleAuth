//
//  SimpleAuthConstantContactProvider.m
//  SimpleAuth
//
//  Created by Tal Kain <tal@kain.net>.
//  Based on BoxWeb's provider created by dkhamsing and FoursquareWeb's provider created by Julien Seren-Rosso
//  Copyright (c) 2015 Fire Place Inc. All rights reserved.
//

#import "SimpleAuthConstantContactProvider.h"
#import "SimpleAuthConstantContactLoginViewController.h"
#import "SimpleAuthConstantContactConstants.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import "UIViewController+SimpleAuthAdditions.h"

@implementation SimpleAuthConstantContactProvider

#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"constantcontact";
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
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        dispatch_async(dispatch_get_main_queue(), ^{
            SimpleAuthConstantContactLoginViewController *login = [[SimpleAuthConstantContactLoginViewController alloc] initWithOptions:self.options];
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

- (RACSignal *)accountWithAccessToken:(NSDictionary *)accessToken {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSDictionary *parameters = @{ @"api_key" : self.options[@"client_id"] };
        NSString *query = [CMDQueryStringSerialization queryStringWithDictionary:parameters];
        NSString *URLString = [NSString stringWithFormat:@"%@?%@", CONSTANT_CONTACT_INFO_END_POINT_URI, query];

        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
        NSString *oauthCode = [NSString stringWithFormat:@"Bearer %@", accessToken];
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
        @"token" : accessToken,
        @"type" : @"token",
    };
    
    // User ID
    dictionary[@"id"] = account[@"email"];
    
    // Raw response
    dictionary[@"extra"] = @{
        @"raw_info" : account
    };
    
    // User info
    NSMutableDictionary *user = [NSMutableDictionary new];
    user[@"login"] = account[@"email"];
    user[@"name"] = [NSString stringWithFormat:@"%@ %@", account[@"first_name"], account[@"last_name"]];
    user[@"phone"] = account[@"phone"];
    dictionary[@"info"] = user;
    
    return dictionary;
}

@end
