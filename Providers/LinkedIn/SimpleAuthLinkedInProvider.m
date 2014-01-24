//
//  SimpleAuthLinkedInProvider.m
//  SimpleAuth
//
//  Created by Abhishek Sheth on 24/01/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthLinkedInProvider.h"
#import "SimpleAuthLinkedInWebLoginViewController.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import "UIViewController+SimpleAuthAdditions.h"

@implementation SimpleAuthLinkedInProvider

#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"LinkedIn";
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
            SimpleAuthLinkedInWebLoginViewController *login = [[SimpleAuthLinkedInWebLoginViewController alloc] initWithOptions:self.options];
            login.completion = ^(UIViewController *login, NSURL *URL, NSError *error) {
                SimpleAuthInterfaceHandler dismissBlock = self.options[SimpleAuthDismissInterfaceBlockKey];
                dismissBlock(login);
                
                // Parse URL
                NSString *fragment = [URL query];
                NSDictionary *dictionary = [CMDQueryStringSerialization dictionaryWithQueryString:fragment];
                NSString *code = dictionary[@"code"];
                
                // Check for error
                if (![code length]) {
                    [subscriber sendError:nil];
                    return;
                }
                
                NSMutableURLRequest *request = [self tokenURLRequestForCode:code];
                [NSURLConnection sendAsynchronousRequest:request queue:self.operationQueue
                                       completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                           NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                                           
                                           NSString *token = [json objectForKey:@"access_token"];
                                           
                                           if (![token length]) {
                                               [subscriber sendError:nil];
                                               return;
                                           }
                                           
                                           // Send completion
                                           [subscriber sendNext:token];
                                           [subscriber sendCompleted];
                                       }];
            };
            
            SimpleAuthInterfaceHandler block = self.options[SimpleAuthPresentInterfaceBlockKey];
            block(login);
        });
        return nil;
    }];
}


- (RACSignal *)accountWithAccessToken:(NSString *)accessToken {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionary];
        [mutableParameters setValue:accessToken forKey:@"oauth2_access_token"];
        [mutableParameters setValue:@"json" forKey:@"format"];
        
        NSDictionary *parameters = [NSDictionary dictionaryWithDictionary:mutableParameters];
        NSString *query = [CMDQueryStringSerialization queryStringWithDictionary:parameters];
        NSString *URLString = [NSString stringWithFormat:@"https://api.linkedin.com/v1/people/~?%@", query];
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
    
    // Provider
    dictionary[@"provider"] = [[self class] type];
    
    // Credentials
    dictionary[@"credentials"] = @{
                                   @"token" : accessToken
                                   };
    
    // User ID
    //dictionary[@"uid"] = account[@"id"];
    
    // Raw response
    dictionary[@"raw_info"] = account;
    
    // User info
    NSMutableDictionary *user = [NSMutableDictionary new];
    user[@"first_name"] = account[@"firstName"];
    user[@"last_name"] = account[@"lastName"];
    user[@"headline"] = account[@"headline"];
    dictionary[@"user_info"] = user;
    
    return dictionary;
}

- (NSDictionary*)parseURLParams:(NSString *)query {
	NSArray *pairs = [query componentsSeparatedByString:@"&"];
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	for (NSString *pair in pairs) {
		NSArray *kv = [pair componentsSeparatedByString:@"="];
		NSString *val = [[kv objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
		[params setObject:val forKey:[kv objectAtIndex:0]];
	}
    return params;
}

-(NSMutableURLRequest *)tokenURLRequestForCode:(NSString *)code
{
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:code, @"code",
                                self.options[@"client_id"], @"client_id",
                                self.options[@"client_secret"], @"client_secret",
                                self.options[@"redirect_uri"], @"redirect_uri",
                                @"authorization_code", @"grant_type",nil];
    
    NSString *query = [CMDQueryStringSerialization queryStringWithDictionary:parameters];
    
    NSString *URLString = [NSString stringWithFormat:@"https://api.linkedin.com/uas/oauth2/accessToken"];
    NSURL *cURL = [NSURL URLWithString:URLString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:cURL];
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", @"utf-8"] forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[query dataUsingEncoding:4]];
    
    return request;
}

@end
