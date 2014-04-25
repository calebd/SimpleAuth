//
//  SimpleAuthFeedlyWebProvider.m
//  SimpleAuth
//
//  Created by Luís Portela Afonso on 26/02/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthFeedlyWebProvider.h"
#import "SimpleAuthFeedlyWebLoginViewController.h"
#import "UIViewController+SimpleAuthAdditions.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

@implementation SimpleAuthFeedlyWebProvider

#pragma mark - SimpleAuthProvider

+ (NSString *)type {
	return @"feedly-web";
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
    dictionary[@"scope"] = @"https://cloud.feedly.com/subscriptions";
    return dictionary;
}


- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion {
	[[[[self authenticationCode]
     flattenMap:^(NSString *code) {
         return [self accessTokenWithAuthenticationCode:code];
     }]
     flattenMap:^(NSDictionary *accessToken) {
         NSArray *signals = @[
             [RACSignal return:accessToken],
             [self accountWithAccessToken:accessToken]
         ];
         return [self rac_liftSelector:@selector(dictionaryWithAccessTokenResponse:accountResponse:) withSignalsFromArray:signals];
     }]
     subscribeNext:^(NSDictionary *dictionary) {
         completion(dictionary, nil);
     }
     error:^(NSError *error) {
         completion(nil, error);
     }];
}


#pragma mark - Private

- (RACSignal*)authenticationCode {
	return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		dispatch_async(dispatch_get_main_queue(), ^{
			SimpleAuthFeedlyWebLoginViewController *login = [[SimpleAuthFeedlyWebLoginViewController alloc] initWithOptions:self.options];
			login.completion = ^(UIViewController *controller, NSURL *URL, NSError *error) {
                SimpleAuthInterfaceHandler block = self.options[SimpleAuthDismissInterfaceBlockKey];
                block(controller);
                
                // Parse URL
                NSString *query = [URL query];
				NSDictionary *dictionary = [CMDQueryStringSerialization dictionaryWithQueryString:query];
				id code = dictionary[@"code"];
                
                // Check for error
                if (!code) {
                    [subscriber sendError:error];
                    return ;
                }
                
                // Send completion
                [subscriber sendNext:@"code"];
                [subscriber sendCompleted];
            };
            
            SimpleAuthInterfaceHandler block = self.options[SimpleAuthPresentInterfaceBlockKey];
            block(login);
		});
		return nil;
	}];
}


- (RACSignal *)accessTokenWithAuthenticationCode:(NSString *)code {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        // Build request
        NSDictionary *parameters = @{
            @"code" : code,
            @"client_id" : self.options[@"client_id"],
            @"client_secret" : self.options[@"client_secret"],
            @"redirect_uri" : self.options[@"redirect_uri"],
            @"grant_type" : @"authorization_code",
        };
        NSData *POSTBody = [NSJSONSerialization dataWithJSONObject:parameters options:kNilOptions error:nil];
        NSURL *URL = [NSURL URLWithString:@"http://feedly.com/v3/auth/token"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:POSTBody];
        
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
        
        // Return
        return nil;
    }];
}


- (RACSignal *)accountWithAccessToken:(NSDictionary *)accessToken {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:nil];
        [subscriber sendCompleted];
        return nil;
    }];
}


- (NSDictionary *)dictionaryWithAccessTokenResponse:(NSDictionary *)accessToken accountResponse:(NSDictionary *)account {
    return accessToken;
}

@end
