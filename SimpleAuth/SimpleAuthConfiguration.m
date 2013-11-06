//
//  SimpleAuthConfiguration.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 SimpleAuth. All rights reserved.
//

#import "SimpleAuthConfiguration.h"

@implementation SimpleAuthConfiguration {
    NSMutableDictionary *_backingStore;
}

#pragma mark - NSObject

- (instancetype)init {
    if ((self = [super init])) {
        _backingStore = [NSMutableDictionary new];
    }
    return self;
}


#pragma mark - Public

- (id)objectForKeyedSubscript:(NSString *)key {
    return _backingStore[key];
}


- (void)setObject:(id)object forKeyedSubscript:(NSString *)key {
    if (object) {
        _backingStore[key] = object;
    }
    else {
        [_backingStore removeObjectForKey:key];
    }
}

@end
