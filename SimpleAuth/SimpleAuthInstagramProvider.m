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
    UIViewController *controller = nil;
    [controller presentViewController:login animated:YES completion:nil];
}

@end
