//
//  SimpleAuthTwitterWebProvider.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 1/15/14.
//  Copyright (c) 2014 Seesaw Decisions Corporation. All rights reserved.
//

#import "SimpleAuthTwitterWebProvider.h"
#import "SimpleAuthTwitterWebLoginViewController.h"

#import "UIViewController+SimpleAuthAdditions.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <cocoa-oauth/GCOAuth.h>

@implementation SimpleAuthTwitterWebProvider

#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"twitter-web";
}


+ (NSDictionary *)defaultOptions {
    
    // Default present block
    SimpleAuthInterfaceHandler presentBlock = ^(UIViewController *controller) {
        UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:controller];
        navigation.modalPresentationStyle = UIModalPresentationFormSheet;
        UIViewController *presented = [UIViewController sa_presentedViewController];
        [presented presentViewController:navigation animated:YES completion:nil];
    };
    
    // Default dismiss block
    SimpleAuthInterfaceHandler dismissBlock = ^(id controller) {
        [controller dismissViewControllerAnimated:YES completion:nil];
    };
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[super defaultOptions]];
    dictionary[SimpleAuthPresentInterfaceBlockKey] = presentBlock;
    dictionary[SimpleAuthDismissInterfaceBlockKey] = dismissBlock;
    dictionary[SimpleAuthRedirectURIKey] = @"simple-auth://twitter-web.auth";
    return dictionary;
}


- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion {
    [self accessTokenWithCompletion:^(id responseObject, NSError *error) {
        
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
                                 host:@"api.twitter.com"
                                 consumerKey:self.options[@"consumer_key"]
                                 consumerSecret:self.options[@"consumer_secret"]
                                 accessToken:nil
                                 tokenSecret:nil];
        [NSURLConnection
         sendAsynchronousRequest:request
         queue:[NSOperationQueue mainQueue]
         completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
             NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 99)];
             NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
             if ([indexSet containsIndex:statusCode] && data) {
                 NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                 [subscriber sendNext:string];
                 [subscriber sendCompleted];
             }
             else {
                 [subscriber sendError:error];
             }
         }];
        return nil;
    }];
}


- (void)accessTokenWithCompletion:(SimpleAuthRequestHandler)completion {
    SimpleAuthTwitterWebLoginViewController *login = [SimpleAuthTwitterWebLoginViewController new];
    
    login.completion = ^(UIViewController *controller, NSURL *URL, NSError *error) {
        SimpleAuthInterfaceHandler block = self.options[SimpleAuthDismissInterfaceBlockKey];
        block(controller);
        
        NSLog(@"%@", URL);
    };
    
    SimpleAuthInterfaceHandler block = self.options[SimpleAuthPresentInterfaceBlockKey];
    block(login);
}

@end
