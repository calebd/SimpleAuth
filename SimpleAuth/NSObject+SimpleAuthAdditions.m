//
//  NSObject+SimpleAuthAdditions.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 1/20/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "NSObject+SimpleAuthAdditions.h"

#import <objc/runtime.h>

@implementation NSObject (SimpleAuthAdditions)

+ (void)SimpleAuth_enumerateSubclassesWithBlock:(void (^) (Class klass))block {
    int numberOfClasses = objc_getClassList(NULL, 0);
    Class allClasses[numberOfClasses];
    objc_getClassList(allClasses, numberOfClasses);
    for (int i = 0; i < numberOfClasses; i++) {
        Class klass = allClasses[i];
        if ([self SimpleAuth_isClass:klass subclassOfClass:self]) {
            block(klass);
        }
    }
}


+ (void)SimpleAuth_enumerateSubclassesExcludingClasses:(NSSet *)set withBlock:(void (^) (Class klass))block {
    [self SimpleAuth_enumerateSubclassesWithBlock:^(Class klass) {
        if (![set containsObject:klass]) {
            block(klass);
        }
    }];
}


+ (BOOL)SimpleAuth_isClass:(Class)classOne subclassOfClass:(Class)classTwo {
    if (classOne == classTwo) {
        return YES;
    }
    Class superclass = class_getSuperclass(classOne);
    if (superclass == Nil) {
        return NO;
    }
    else {
        return [self SimpleAuth_isClass:superclass subclassOfClass:classTwo];
    }
}

@end
