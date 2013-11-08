//
//  SimpleAuthInstagramProvider.m
//  SimpleAuth
//
//  Created by Caleb on 11/7/13.
//  Copyright (c) 2013 SimpleAuth. All rights reserved.
//

#import "SimpleAuthInstagramProvider.h"
#import "SimpleAuth_Internal.h"
#import "SimpleAuthInstagramLoginViewController.h"

#import <SAMCategories/NSDictionary+SAMAdditions.h>

@implementation SimpleAuthInstagramProvider

#pragma mark - NSObject

+ (void)load {
    @autoreleasepool {
        [SimpleAuth registerProviderClass:self];
    }
}


#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"instagram";
}


- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion {
    NSDictionary *configuration = [[self class] configuration];
    SimpleAuthInstagramLoginViewController *login = [[SimpleAuthInstagramLoginViewController alloc] initWithConfiguration:configuration];
    login.completion = ^(id accessTokenResponse, NSError *error) {
        
        // Check access token
        NSString *accessToken = accessTokenResponse[@"access_token"];
        if (accessToken) {
            [self instagramAccountWithAccessToken:accessToken completion:^(id accountResponse, NSHTTPURLResponse *response, NSError *error) {
                NSMutableDictionary *account = [NSMutableDictionary new];
                [account addEntriesFromDictionary:accessTokenResponse];
                [account addEntriesFromDictionary:accountResponse];
                completion(account, nil, nil);
            }];
            return;
        }
        
        // Check error
        completion(nil, nil, nil);
    };
    UIViewController *controller = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [controller presentViewController:login animated:YES completion:nil];
}


#pragma mark - Public

- (void)instagramAccountWithAccessToken:(NSString *)accessToken completion:(SimpleAuthRequestHandler)completion {
    NSDictionary *parameters = @{ @"access_token" : accessToken };
    NSString *query = [parameters sam_stringWithFormEncodedComponents];
    NSString *URLString = [NSString stringWithFormat:@"https://api.instagram.com/v1/users/self?%@", query];
    NSURL *URL = [NSURL URLWithString:URLString];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    [NSURLConnection
     sendAsynchronousRequest:request
     queue:[NSOperationQueue mainQueue]
     completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
         NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
         NSInteger statusCode = [HTTPResponse statusCode];
         if (statusCode == 200 && data) {
             NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
             completion(dictionary[@"data"], nil, nil);
         }
         else {
             completion(nil, HTTPResponse, error);
         }
     }];
}

@end
