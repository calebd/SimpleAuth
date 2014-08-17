//
//  SimpleAuthTripItProvider.m
//  SimpleAuth
//
//  Created by Mark Krenek on 8/15/14.
//  Copyright (c) 2014 Mark Krenek. All rights reserved.
//

#import "SimpleAuthTripItProvider.h"
#import "SimpleAuthTripItLoginViewController.h"

#import "UIViewController+SimpleAuthAdditions.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <cocoa-oauth/GCOAuth.h>

@implementation SimpleAuthTripItProvider

#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"tripit";
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
    dictionary[SimpleAuthRedirectURIKey] = @"simple-auth://tripit.auth";
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
                                 host:@"api.tripit.com"
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
            SimpleAuthTripItLoginViewController *login = [[SimpleAuthTripItLoginViewController alloc] initWithOptions:self.options requestToken:requestToken];
            
            login.completion = ^(UIViewController *controller, NSURL *URL, NSError *error) {
                SimpleAuthInterfaceHandler block = self.options[SimpleAuthDismissInterfaceBlockKey];
                block(controller);
                
                // Parse URL
                NSString *query = [URL query];
                NSDictionary *dictionary = [CMDQueryStringSerialization dictionaryWithQueryString:query];
                NSString *token = dictionary[@"oauth_token"];

                // Check for error
                if (![token length]) {
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
        NSDictionary *parameters = @{  };
        NSURLRequest *request = [GCOAuth
                                 URLRequestForPath:@"/oauth/access_token"
                                 POSTParameters:parameters
                                 scheme:@"https"
                                 host:@"api.tripit.com"
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
        NSDictionary* parameters = @{ @"format" : @"json" };
        NSURLRequest *request = [GCOAuth
                                 URLRequestForPath:@"/v1/get/profile"
                                 GETParameters:parameters
                                 scheme:@"https"
                                 host:@"api.tripit.com"
                                 consumerKey:self.options[@"consumer_key"]
                                 consumerSecret:self.options[@"consumer_secret"]
                                 accessToken:accessToken[@"oauth_token"]
                                 tokenSecret:accessToken[@"oauth_token_secret"]];
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
    
    //    {
    //        "timestamp": "1408218794", 
    //        "num_bytes": "6329", 
    //        "Profile": {
    //            "@attributes": {
    //                "ref": "ABCDEFGHIJKL"
    //            }, 
    //            "ProfileEmailAddresses": {
    //                "ProfileEmailAddress": {
    //                    "address": "johndoe@example.com",
    //                    "is_auto_import": "false", 
    //                    "is_confirmed": "true", 
    //                    "is_primary": "true", 
    //                    "is_auto_inbox_eligible": "false"
    //                }
    //            }, 
    //            "NotificationSettings": {}, 
    //            "is_client": "true", 
    //            "is_pro": "false", 
    //            "screen_name": "johndoe",
    //            "public_display_name": "John Joe",
    //            "profile_url": "people/johdoe",
    //            "alerts_feed_url": "https://www.tripit.com/feed/alerts/private/ABCDEFG/alerts.atom",
    //            "ical_url": "webcal://www.tripit.com/feed/ical/private/ABCDEFG/tripit.ics"
    //        }
    //    }

    // Provider
    dictionary[@"provider"] = [[self class] type];
    
    // Credentials
    dictionary[@"credentials"] = @{
        @"token" : accessToken[@"oauth_token"],
        @"secret" : accessToken[@"oauth_token_secret"]
    };
    
    // User ID
    [dictionary setValue:account[@"Profile"][@"@attributes"][@"ref"]   // Yes, attributes is prefixed with an @
            forKey:@"uid"];

    // Extra
    dictionary[@"extra"] = @{
        @"raw_info" : account,
    };
    
    // User info
    NSMutableDictionary *user = [NSMutableDictionary new];
    [user setValue:[account valueForKeyPath:@"Profile.screen_name"]
            forKey:@"nickname"];

    [user setValue:[account valueForKeyPath:@"Profile.public_display_name"]
            forKey:@"name"];

    [user setValue:[account valueForKeyPath:@"Profile.ProfileEmailAddresses.ProfileEmailAddress.address"]
            forKey:@"email"];

    dictionary[@"info"] = user;
    
    return dictionary;
}

@end
