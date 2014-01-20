//
//  SimpleAuth.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 Seesaw Decisions Corporation. All rights reserved.
//

#import "SimpleAuthProvider.h"

#import <objc/runtime.h>

NSString * const SimpleAuthErrorDomain = @"SimpleAuthErrorDomain";
NSString * const SimpleAuthPresentInterfaceBlockKey = @"present_interface_block";
NSString * const SimpleAuthDismissInterfaceBlockKey = @"dismiss_interface_block";
NSString * const SimpleAuthRedirectURIKey = @"redirect_uri";

NSInteger const SimpleAuthUserCancelledErrorCode = NSUserCancelledError;

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


+ (BOOL)isProviderClass:(Class)klass {
    if (klass == [SimpleAuthProvider class]) {
        return YES;
    }
    Class superclass = class_getSuperclass(klass);
    if (superclass == Nil) {
        return NO;
    }
    else {
        return [self isProviderClass:superclass];
    }
}


+ (void)loadProviders {
    int count = objc_getClassList(NULL, 0);
    Class classes[count];
    objc_getClassList(classes, count);
    for (int i = 0; i < count; i++) {
        Class klass = classes[i];
        if ([self isProviderClass:klass]) {
            NSString *type = [klass type];
            if (type) {
                [self registerProviderClass:klass];
            }
        }
    }
}

@end
