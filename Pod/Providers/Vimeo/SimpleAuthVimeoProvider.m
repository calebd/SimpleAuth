//
//  SimpleAuthVimeoProvider.m
//  SimpleAuth
//
//  Created by Martin Pilch on 21/4/15.
//  Copyright (c) 2015 Martin Pilch, All rights reserved.
//

#import "SimpleAuthVimeoProvider.h"
#import "SimpleAuthVimeoLoginViewController.h"

#import "UIViewController+SimpleAuthAdditions.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@implementation SimpleAuthVimeoProvider

#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"vimeo";
}

+ (NSString *)authorizationHeaderWithClientID:(NSString *)clientID clientSecret:(NSString *)clientSecret
{
    NSString *base = [[clientID stringByAppendingString:@":"] stringByAppendingString:clientSecret];
    NSData *plainData = [base dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64String = [plainData base64EncodedStringWithOptions:0];
    return [@"basic " stringByAppendingString:base64String];
}


NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

+ (NSString *)randomStringWithLength:(int)len
{
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    for ( NSInteger i = 0; i < len; i++ ) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((u_int32_t)[letters length])]];
    }
    return randomString;
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
    options[SimpleAuthRedirectURIKey] = @"http://";
    options[@"state"] = [self randomStringWithLength:20];
    
    return options;
}

- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion {
    [[[self accessToken]
      flattenMap:^(id responseObject) {
          NSArray *signals = @[
                               [self accountWithAccessToken:responseObject],
                               [RACSignal return:responseObject]
                               ];
          return [self rac_liftSelector:@selector(dictionaryWithAccount:accessToken:) withSignalsFromArray:signals];
      }]
     subscribeNext:^(id responseObject) {
         completion(responseObject, nil);
     }
     error:^(NSError *error) {
         completion(nil, error);
     }];
}

#pragma mark - Private

- (RACSignal *)authorizationCode {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        dispatch_async(dispatch_get_main_queue(), ^{
            SimpleAuthVimeoLoginViewController *login = [[SimpleAuthVimeoLoginViewController alloc] initWithOptions:self.options];
            login.completion = ^(UIViewController *login, NSURL *URL, NSError *error) {
                SimpleAuthInterfaceHandler dismissBlock = self.options[SimpleAuthDismissInterfaceBlockKey];
                dismissBlock(login);
                
                // Parse URL
                NSString *fragment = [URL query];
                NSDictionary *dictionary = [CMDQueryStringSerialization dictionaryWithQueryString:fragment];
                NSString *code = dictionary[@"code"];
                NSString *state = dictionary[@"state"];
                
                // Check for error
                if (![code length]) {
                    [subscriber sendError:error];
                    return;
                }

                if (![state isEqualToString:self.options[@"state"]]) {
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
                                     @"grant_type" : @"authorization_code",
                                     @"redirect_uri" : self.options[SimpleAuthRedirectURIKey],
                                     };
        NSString *query = [CMDQueryStringSerialization queryStringWithDictionary:parameters];
        NSString *authorizationHeader = [self.class authorizationHeaderWithClientID:self.options[@"client_id"]
                                                                       clientSecret:self.options[@"client_secret"]];
        NSURL *URL = [NSURL URLWithString:@"https://api.vimeo.com/oauth/access_token"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
        request.HTTPMethod = @"POST";
        request.HTTPBody = [query dataUsingEncoding:NSUTF8StringEncoding];
        [request setValue:authorizationHeader forHTTPHeaderField:@"Authorization"];
        
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
        NSDictionary *parameters = @{
                                     @"access_token" : accessToken[@"access_token"],
                                     };
        NSString *URLString =  [NSString stringWithFormat:@"https://api.vimeo.com/me?%@",
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
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    // Provider
    dictionary[@"provider"] = [[self class] type];
    
    // Credentials
    dictionary[@"credentials"] = @{@"token" : accessToken[@"access_token"]};
    
    // User ID
    dictionary[@"uid"] = account[@"uri"];
    
    // Raw response
    dictionary[@"extra"] = @{
        @"raw_info" : account
    };
    
    // User info
    NSMutableDictionary *user = [NSMutableDictionary new];
    user[@"name"] = account[@"name"];
    dictionary[@"info"] = user;
    
    return dictionary;
}

@end
