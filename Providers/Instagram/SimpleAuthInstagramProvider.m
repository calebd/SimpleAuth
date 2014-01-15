//
//  SimpleAuthInstagramProvider.m
//  SimpleAuthInstagram
//
//  Created by Caleb Davenport on 11/7/13.
//  Copyright (c) 2013 Seesaw Decisions Corporation. All rights reserved.
//

#import "SimpleAuthInstagramProvider.h"
#import "SimpleAuthInstagramLoginViewController.h"

#import "UIViewController+SimpleAuthAdditions.h"

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


+ (NSDictionary *)defaultOptions {
    SimpleAuthInterfaceHandler presentBlock = ^(UIViewController *controller) {
        UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:controller];
        navigation.modalPresentationStyle = UIModalPresentationFormSheet;
        UIViewController *presented = [UIViewController sa_presentedViewController];
        [presented presentViewController:navigation animated:YES completion:nil];
    };
    SimpleAuthInterfaceHandler dismissBlock = ^(id controller) {
        [controller dismissViewControllerAnimated:YES completion:nil];
    };
    
    NSMutableDictionary *options = [[super defaultOptions] mutableCopy];
    options[@"present_interface_block"] = presentBlock;
    options[@"dismiss_interface_block"] = dismissBlock;
    return options;
}


- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion {
    SimpleAuthInstagramLoginViewController *login = [[SimpleAuthInstagramLoginViewController alloc] initWithOptions:self.options];
    login.completion = ^(SimpleAuthWebViewController *controller, id responseObject, NSError *error) {
        SimpleAuthInterfaceHandler dismissBlock = self.options[@"dismiss_interface_block"];
        dismissBlock(controller);
        
        // Check access token
        NSString *accessToken = responseObject[@"access_token"];
        if (accessToken) {
            [self instagramAccountWithAccessToken:accessToken completion:^(id accountResponse, NSError *error) {
                completion(accountResponse, nil);
            }];
            return;
        }
        else {
            completion(nil, error);
        }
    };
    
    SimpleAuthInterfaceHandler block = self.options[@"present_interface_block"];
    block(login);
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
         NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
         if (statusCode == 200 && data) {
             NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
             dictionary = dictionary[@"data"];
             dictionary = [self dictionaryWithResponseObject:dictionary accessToken:accessToken];
             completion(dictionary, nil);
         }
         else {
             completion(nil, error);
         }
     }];
}


#pragma mark - Private

- (NSDictionary *)dictionaryWithResponseObject:(NSDictionary *)responseObject accessToken:(NSString *)accessToken {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    
    // Provider
    dictionary[@"provider"] = [[self class] type];
    
    // Credentials
    dictionary[@"credentials"] = @{
        @"token" : accessToken
    };
    
    // User ID
    dictionary[@"uid"] = responseObject[@"id"];
    
    // Raw response
    dictionary[@"raw_info"] = responseObject;
    
    // User info
    NSMutableDictionary *user = [NSMutableDictionary new];
    user[@"name"] = responseObject[@"full_name"];
    user[@"username"] = responseObject[@"username"];
    user[@"image"] = responseObject[@"profile_picture"];
    dictionary[@"user_info"] = user;
    
    return dictionary;
}

@end
