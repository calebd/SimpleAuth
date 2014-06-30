//
//  SimpleAuthFlickrWebProvider.m
//  SimpleAuth
//
//  Created by David Caunt on 29/06/2014.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthFlickrWebProvider.h"
#import "SimpleAuthFlickrWebLoginViewController.h"

#import "UIViewController+SimpleAuthAdditions.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <cocoa-oauth/GCOAuth.h>

@implementation SimpleAuthFlickrWebProvider

#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"flickr-web";
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
    dictionary[SimpleAuthRedirectURIKey] = @"simple-auth://flickr.auth";
    dictionary[@"perms"] = @"read";
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
                                 URLRequestForPath:@"/services/oauth/request_token"
                                 POSTParameters:parameters
                                 scheme:@"https"
                                 host:@"www.flickr.com"
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
            SimpleAuthFlickrWebLoginViewController *login = [[SimpleAuthFlickrWebLoginViewController alloc] initWithOptions:self.options requestToken:requestToken];

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
                                 URLRequestForPath:@"/services/oauth/access_token"
                                 POSTParameters:parameters
                                 scheme:@"https"
                                 host:@"www.flickr.com"
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
        NSDictionary *parameters = @{
            @"format": @"json",
            @"nojsoncallback": @"1",
            @"method": @"flickr.people.getInfo",
            @"user_id": accessToken[@"user_nsid"]
        };
        NSURLRequest *request = [GCOAuth
                                 URLRequestForPath:@"/services/rest"
                                 GETParameters:parameters
                                 scheme:@"https"
                                 host:@"api.flickr.com"
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
                     dictionary = dictionary[@"person"];
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
    dictionary[@"uid"] = account[@"id"];

    // Extra
    dictionary[@"extra"] = @{
        @"raw_info" : account,
    };

    // Profile image
    NSUInteger iconFarm = [account[@"iconfarm"] unsignedIntegerValue];
    NSString *avatar = [NSString stringWithFormat:@"https://farm%d.staticflickr.com/%@/buddyicons/%@_m.jpg", iconFarm, account[@"iconserver"], account[@"id"]];

    // User info & Optionals
    NSMutableDictionary *user = [NSMutableDictionary new];
    user[@"pro"] = account[@"ispro"];
    [user setValue:account[@"realname"][@"_content"] forKey:@"name"];
    [user setValue:account[@"username"][@"_content"] forKey:@"username"];
    [user setValue:account[@"description"][@"_content"] forKey:@"description"];
    [user setValue:account[@"location"][@"_content"] forKey:@"location"];

    user[@"image"] = avatar;

    NSMutableDictionary *URLs = [NSMutableDictionary new];
    [URLs setValue:account[@"mobileurl"][@"_content"] forKey:@"mobile"];
    [URLs setValue:account[@"photosurl"][@"_content"] forKey:@"photos"];
    [URLs setValue:account[@"profileurl"][@"_content"] forKey:@"profile"];
    user[@"urls"] = URLs;

    dictionary[@"info"] = user;
    return dictionary;
}

@end
