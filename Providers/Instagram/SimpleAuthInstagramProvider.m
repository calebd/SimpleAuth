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
    
    NSMutableDictionary *options = [NSMutableDictionary dictionaryWithDictionary:[super defaultOptions]];
    options[SimpleAuthPresentInterfaceBlockKey] = presentBlock;
    options[SimpleAuthDismissInterfaceBlockKey] = dismissBlock;
    return options;
}


- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion {
    [self accessTokenWithCompletion:^(NSString *accessToken, NSError *error) {
        if (!accessToken) {
            completion(nil, error);
        }
        
        [self instagramAccountWithAccessToken:accessToken completion:^(NSDictionary *account, NSError *error) {
            if (!account) {
                completion(nil, error);
            }
            
            NSDictionary *dictionary = [self dictionaryWithAccount:account accessToken:accessToken];
            completion(dictionary, nil);
        }];
    }];
}


#pragma mark - Public

- (void)accessTokenWithCompletion:(SimpleAuthRequestHandler)completion {
    SimpleAuthInstagramLoginViewController *login = [[SimpleAuthInstagramLoginViewController alloc] initWithOptions:self.options];
    login.completion = ^(UIViewController *login, NSURL *URL, NSError *error) {
        
        // Dismiss controller
        SimpleAuthInterfaceHandler dismissBlock = self.options[SimpleAuthDismissInterfaceBlockKey];
        dismissBlock(login);
        
        // Check for access token
        NSString *fragment = [URL fragment];
        if ([fragment length]) {
            NSDictionary *dictionary = [NSDictionary sam_dictionaryWithFormEncodedString:fragment];
            NSString *string = dictionary[@"access_token"];
            completion(string, nil);
        }
        else {
            completion(nil, error);
        }
    };
    
    SimpleAuthInterfaceHandler block = self.options[SimpleAuthPresentInterfaceBlockKey];
    block(login);
}


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
         NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 99)];
         NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
         if ([indexSet containsIndex:statusCode] && data) {
             NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
             if (dictionary) {
                 completion(dictionary, nil);
             }
             else {
                 completion(nil, error);
             }
         }
         else {
             completion(nil, error);
         }
     }];
}


#pragma mark - Private

- (NSDictionary *)dictionaryWithAccount:(NSDictionary *)account accessToken:(NSString *)accessToken {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    NSDictionary *data = account[@"data"];
    
    // Provider
    dictionary[@"provider"] = [[self class] type];
    
    // Credentials
    dictionary[@"credentials"] = @{
        @"token" : accessToken
    };
    
    // User ID
    dictionary[@"uid"] = data[@"id"];
    
    // Raw response
    dictionary[@"raw_info"] = account;
    
    // User info
    NSMutableDictionary *user = [NSMutableDictionary new];
    user[@"name"] = data[@"full_name"];
    user[@"username"] = data[@"username"];
    user[@"image"] = data[@"profile_picture"];
    dictionary[@"user_info"] = user;
    
    return dictionary;
}

@end
