//
//  SimpleAuth.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 Seesaw Decisions Corporation. All rights reserved.
//

#import "SimpleAuthProvider.h"

@implementation SimpleAuth

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
    [provider authorizeWithCompletion:^(id responseObject, NSHTTPURLResponse *response, NSError *error) {
        completion(responseObject, response, error);
        [provider class]; // Kepp the provider around until the callback is complete
    }];
}


#pragma mark - Internal

+ (void)registerProviderClass:(Class)klass {
    NSMutableDictionary *providers = [self providers];
    NSString *type = [klass type];
    if (providers[type]) {
        NSLog(@"[SimpleAuth] Warning: multiple attempts to register profider: %@", type);
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


+ (NSMutableDictionary *)providerOptions {
    static dispatch_once_t token;
    static NSMutableDictionary *options;
    dispatch_once(&token, ^{
        options = [NSMutableDictionary new];
    });
    return options;
}

@end
