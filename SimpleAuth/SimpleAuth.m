//
//  SimpleAuth.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013-2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthProvider.h"

#import "NSObject+SimpleAuthAdditions.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

NSString * const SimpleAuthErrorDomain = @"SimpleAuthErrorDomain";
NSString * const SimpleAuthPresentInterfaceBlockKey = @"present_interface_block";
NSString * const SimpleAuthDismissInterfaceBlockKey = @"dismiss_interface_block";
NSString * const SimpleAuthRedirectURIKey = @"redirect_uri";

@implementation SimpleAuth

#pragma mark - NSObject

+ (void)initialize {
    [self loadProviders];
}


#pragma mark - Public

+ (NSMutableDictionary *)configuration {
    static dispatch_once_t token;
    static NSMutableDictionary *configuration;
    dispatch_once(&token, ^{
        configuration = [NSMutableDictionary new];
    });
    return configuration;
}


+ (void)authorize:(NSString *)type completion:(SimpleAuthRequestHandler)completion {
    [self authorize:type options:nil completion:completion];
}


+ (void)authorize:(NSString *)type options:(NSDictionary *)options completion:(SimpleAuthRequestHandler)completion {
    
    // Load the provider class
    Class klass = [self providers][type];
    NSAssert(klass, @"There is no class registered to handle %@ requests.", type);
    
    // Create options dictionary
    NSDictionary *defaultOptions = [klass defaultOptions];
    NSDictionary *registeredOptions = [self configuration][type];
    NSMutableDictionary *resolvedOptions = [NSMutableDictionary new];
    [resolvedOptions addEntriesFromDictionary:defaultOptions];
    [resolvedOptions addEntriesFromDictionary:registeredOptions];
    [resolvedOptions addEntriesFromDictionary:options];
    
    // Create the provider and run authorization
    SimpleAuthProvider *provider = [(SimpleAuthProvider *)[klass alloc] initWithOptions:resolvedOptions];
    [provider authorizeWithCompletion:^(id responseObject, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(responseObject, error);
        });
        [provider class]; // Kepp the provider around until the callback is complete
    }];
}


#pragma mark - Internal

+ (void)registerProviderClass:(Class)klass {
    NSMutableDictionary *providers = [self providers];
    NSString *type = [klass type];
    if (providers[type]) {
        NSLog(@"[SimpleAuth] Warning: multiple attempts to register profider: %@", type);
        return;
    }
    providers[type] = klass;
}


#pragma mark - Private

+ (NSMutableDictionary *)providers {
    static dispatch_once_t token;
    static NSMutableDictionary *providers;
    dispatch_once(&token, ^{
        providers = [NSMutableDictionary new];
    });
    return providers;
}


+ (void)loadProviders {
    NSSet *set = [NSSet setWithArray:@[
        [SimpleAuthProvider class]
    ]];
    [SimpleAuthProvider SimpleAuth_enumerateSubclassesExcludingClasses:set withBlock:^(Class klass) {
        [self registerProviderClass:klass];
    }];
}

@end
