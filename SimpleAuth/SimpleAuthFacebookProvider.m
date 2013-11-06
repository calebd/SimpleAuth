//
//  SimpleAuthFacebookProvider.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 SimpleAuth. All rights reserved.
//

#import "SimpleAuthFacebookProvider.h"
#import "SimpleAuth_Internal.h"

@implementation SimpleAuthFacebookProvider

+ (void)load {
    @autoreleasepool {
        [SimpleAuth registerProviderClass:self];
    }
}

@end
