//
//  SimpleAuth.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013-2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuth.h"
#import "SimpleAuthProvider.h"
#import "SimpleAuthSingleSignOnProvider.h"
#import "NSObject+SimpleAuthAdditions.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

NSString * const SimpleAuthPresentInterfaceBlockKey = @"present_interface_block";
NSString * const SimpleAuthDismissInterfaceBlockKey = @"dismiss_interface_block";
NSString * const SimpleAuthRedirectURIKey = @"redirect_uri";

static SimpleAuthProvider *__currentProvider = nil;

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

+ (void)authenticateWithProvider:(NSString * )provider completion:(SimpleAuthRequestHandler)completion {
    [self authenticateWithProvider:provider options:nil completion:completion];
}

+ (void)authenticateWithProvider:(NSString *)provider options:(NSDictionary *)options completion:(SimpleAuthRequestHandler)completion {
    NSParameterAssert(completion);
    NSParameterAssert(provider);
    
    // Load the provider class
    Class klass = [self providers][provider];
    NSAssert(klass, @"There is no class registered to handle %@ requests.", provider);
    
    // Create options dictionary
    NSDictionary *defaultOptions = [klass defaultOptions];
    NSDictionary *registeredOptions = [self configuration][provider];
    NSMutableDictionary *resolvedOptions = [NSMutableDictionary new];
    [resolvedOptions addEntriesFromDictionary:defaultOptions];
    [resolvedOptions addEntriesFromDictionary:registeredOptions];
    [resolvedOptions addEntriesFromDictionary:options];
    
    // Create the provider and run authorization
    __currentProvider = [(SimpleAuthProvider *)[klass alloc] initWithOptions:resolvedOptions];
    [__currentProvider authorizeWithCompletion:^(id responseObject, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(responseObject, error);
        });
    }];
}

+ (void)authenticateWithProviders:(NSArray *)providers completion:(SimpleAuthRequestHandler)completion {
    [self authenticateWithProviders:providers options:nil completion:completion];
}

+ (void)authenticateWithProviders:(NSArray *)providers options:(NSDictionary *)options completion:(SimpleAuthRequestHandler)completion {
    NSParameterAssert([providers count] > 0);
    NSParameterAssert(completion);
    [self authenticateWithProviderAtIndex:0 inProviders:providers options:options completion:completion];
}

+ (BOOL)handleCallback:(NSURL *)URL {
    NSParameterAssert(URL != nil);

    NSAssert(__currentProvider != nil, @"There is no provider waiting for single sign on callback.");
    NSAssert([__currentProvider conformsToProtocol:@protocol(SimpleAuthSingleSignOnProvider)], @"The current provider does not handle single sign on.");
    
    return [(id<SimpleAuthSingleSignOnProvider>)__currentProvider handleCallback:URL];
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

+ (void)registerProviderClass:(Class)klass {
    NSMutableDictionary *providers = [self providers];
    NSString *type = [klass type];
    if (providers[type]) {
        NSLog(@"[SimpleAuth] Warning: multiple attempts to register provider for type: %@", type);
        return;
    }
    providers[type] = klass;
}

+ (void)loadProviders {
    [SimpleAuthProvider SimpleAuth_enumerateSubclassesWithBlock:^(Class klass, BOOL *stop) {
        [self registerProviderClass:klass];
    }];
}

+ (void)authenticateWithProviderAtIndex:(NSUInteger)index inProviders:(NSArray *)providers options:(NSDictionary *)options completion:(SimpleAuthRequestHandler)completion {
    NSUInteger numberOfProviders = [providers count];
    NSString *provider = providers[index];
    [self authenticateWithProvider:provider options:options completion:^(id responseObject, NSError *error) {
        
        // Success
        if (responseObject) {
            completion(responseObject, nil);
            return;
        }
        
        // User cancelled
        if ([error.domain isEqualToString:SimpleAuthErrorDomain] && error.code == SimpleAuthErrorUserCancelled) {
            completion(nil, error);
            return;
        }
        
        // Network error
        NSInteger statusCode = [error.userInfo[SimpleAuthErrorStatusCodeKey] integerValue];
        if ([error.domain isEqualToString:SimpleAuthErrorDomain] && error.code == SimpleAuthErrorNetwork && statusCode == 0) {
            completion(nil, error);
            return;
        }
        
        // Last provider
        if (index == numberOfProviders - 1) {
            completion(nil, error);
            return;
        }
        
        // Fall back
        [self authenticateWithProviderAtIndex:(index + 1) inProviders:providers options:options completion:completion];
    }];
}


#pragma mark - Deprecated

+ (void)authorize:(NSString * )provider completion:(SimpleAuthRequestHandler)completion {
    [self authenticateWithProvider:provider options:nil completion:completion];
}

+ (void)authorize:(NSString *)provider options:(NSDictionary *)options completion:(SimpleAuthRequestHandler)completion {
    [self authenticateWithProvider:provider options:nil completion:completion];
}

@end
