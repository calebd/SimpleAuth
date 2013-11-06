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

//+ (void)configureProvider:(NSString *)provider block:(void (^) (NSMutableDictionary *options))block {
//    NSMutableDictionary *providerOptions = [self providerOptions];
//    NSMutableDictionary *options = providerOptions[provider];
//    if (!options) {
//        options = [NSMutableDictionary new];
//        providerOptions[provider] = options;
//    }
//    
//    // TODO: call this in a safe manner
//    block(options);
//}


+ (SimpleAuthConfiguration *)configuration {
    static dispatch_once_t token;
    static SimpleAuthConfiguration *configuration;
    dispatch_once(&token, ^{
        configuration = [SimpleAuthConfiguration new];
    });
    return configuration;
}


+ (void)authorize:(NSString *)provider completion:(void (^) (id response))completion {
    
}


#pragma mark - Internal

+ (void)registerProviderClass:(Class)klass {
    NSMutableDictionary *providers = [self providers];
    NSString *type = [klass type];
    if (providers[type]) {
        Class klass = providers[type];
        NSLog(@"%@ is already registered for %@", NSStringFromClass(klass), type);
    }
    
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


//+ (NSMutableDictionary *)optionsForProvider:(NSString *)provider {
//    
//    // Create provider options collection
//    static dispatch_once_t token;
//    static NSMutableDictionary *providerOptions;
//    dispatch_once(&token, ^{
//        providerOptions = [NSMutableDictionary new];
//    });
//    return providerOptions;
//    
//    // Find or create options
//    NSMutableDictionary *options = providerOptions[provider];
//    if (!options) {
//        options = [NSMutableDictionary new];
//        providerOptions[provider] = options;
//    }
//    
//    // Return
//    return options;
//}


+ (NSMutableDictionary *)providerOptions {
    static dispatch_once_t token;
    static NSMutableDictionary *options;
    dispatch_once(&token, ^{
        options = [NSMutableDictionary new];
    });
    return options;
}

@end
