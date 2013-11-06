//
//  SimpleAuthTwitterProvider.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 SimpleAuth. All rights reserved.
//

#import "SimpleAuthTwitterProvider.h"
#import "SimpleAuth_Internal.h"

@implementation SimpleAuthTwitterProvider

+ (void)load {
    @autoreleasepool {
        [SimpleAuth registerProviderClass:self];
    }
}

@end
