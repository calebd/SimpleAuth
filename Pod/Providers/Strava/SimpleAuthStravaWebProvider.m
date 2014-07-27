//
//  SimpleAuthStravaWebProvider.m
//  SimpleAuth
//
//  Created by Ben Stahl on 7/27/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthStravaWebProvider.h"
#import "SimpleAuthStravaWebLoginViewController.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import "UIViewController+SimpleAuthAdditions.h"

@implementation SimpleAuthStravaWebProvider

#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"strava-web";
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
            SimpleAuthStravaWebLoginViewController *login = [[SimpleAuthStravaWebLoginViewController alloc] initWithOptions:self.options];
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
                                     @"redirect_uri" : self.options[SimpleAuthRedirectURIKey],
                                     };
        NSString *query = [CMDQueryStringSerialization queryStringWithDictionary:parameters];
        NSURL *URL = [NSURL URLWithString:@"https://www.strava.com/oauth/token"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
        request.HTTPMethod = @"POST";
		request.HTTPBody = [query dataUsingEncoding:NSUTF8StringEncoding];
        
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
        NSString *URLString =  [NSString stringWithFormat:@"https://www.strava.com/api/v3/athlete?%@",
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
    dictionary[@"uid"] = account[@"id"];
    
    // Raw response
    dictionary[@"raw_info"] = account;
    
    // User info
    NSMutableDictionary *user = [NSMutableDictionary new];
    user[@"email"] = account[@"email"];
    if (user[@"firstName"]) {
        user[@"first_name"] = user[@"firstname"];
    }
    if (user[@"lastName"]) {
        user[@"last_name"] = user[@"lastname"];
    }
    user[@"gender"] = account[@"sex"];
    user[@"image"] = account[@"profile"];
    user[@"location"] = account[@"city"];
    dictionary[@"info"] = user;
    
    return dictionary;
}


@end
