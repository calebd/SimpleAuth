//
//  SimpleAuth.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 SimpleAuth. All rights reserved.
//

#import "SimpleAuth_Internal.h"
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
    Class klass = [self providers][type];
    SimpleAuthProvider *provider = [klass new];
    [provider authorizeWithCompletion:^(id responseObject, NSHTTPURLResponse *response, NSError *error) {
        completion(responseObject, response, error);
        [provider class]; // Keep the provider around until the work is done
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
