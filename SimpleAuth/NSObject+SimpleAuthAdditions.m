//
//  NSObject+SimpleAuthAdditions.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 1/20/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "NSObject+SimpleAuthAdditions.h"
#import "SimpleAuthFunctions.h"

@implementation NSObject (SimpleAuthAdditions)

+ (void)SimpleAuth_enumerateSubclassesWithBlock:(void (^) (Class, BOOL *))block {
    SimpleAuthEnumerateAllSubclassesOfClass(self, block);
}

@end
