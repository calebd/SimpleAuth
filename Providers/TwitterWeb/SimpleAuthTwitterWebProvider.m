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
    return dictionary;
}


- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion {
    [self accessTokenWithCompletion:^(id responseObject, NSError *error) {
        
    }];
}


#pragma mark - Private

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
