//
//  SimpleAuthProvider.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013-2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthProvider.h"
#import "SimpleAuthActivityIndicator.h"
#import "SimpleAuthFunctions.h"

@interface SimpleAuthProvider ()

@property (nonatomic, copy) NSDictionary *options;
@property (nonatomic, readonly) id<SimpleAuthActivityIndicator> activityIndicator;

@end

@implementation SimpleAuthProvider

@synthesize operationQueue = _operationQueue;
@synthesize activityIndicator = _activityIndicator;

#pragma mark - Public

+ (NSString *)type {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}


+ (NSDictionary *)defaultOptions {
    return @{};
}


- (instancetype)initWithOptions:(NSDictionary *)options {
    if ((self = [super init])) {
        self.options = options;
    }
    return self;
}


- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion {
    [self doesNotRecognizeSelector:_cmd];
}


- (void)showActivityIndicator {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicator showActivityIndicatorForSimpleAuthProvider:self];
    });
}


- (void)hideActivityIndicator {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicator hideActivityIndicatorForSimpleAuthProvider:self];
    });
}


#pragma mark - Accessors

- (NSOperationQueue *)operationQueue {
    if (!_operationQueue) {
        _operationQueue = [NSOperationQueue new];
    }
    return _operationQueue;
}


- (id<SimpleAuthActivityIndicator>)activityIndicator {
    if (!_activityIndicator) {
        Class activityIndicatorClass = [[self class] activityIndicatorClass];
        if (activityIndicatorClass == Nil) {
            return nil;
        }
        _activityIndicator = [activityIndicatorClass new];
    }
    return _activityIndicator;
}


#pragma mark - Private

+ (Class)activityIndicatorClass {
    static dispatch_once_t token;
    static Class activityIndicatorClass;
    dispatch_once(&token, ^{
        SimpleAuthEnumerateAllClassesConformingToProtocol(@protocol(SimpleAuthActivityIndicator), ^(__unsafe_unretained Class klass, BOOL *stop) {
            activityIndicatorClass = klass;
            *stop = YES;
        });
    });
    return activityIndicatorClass;
}

@end
