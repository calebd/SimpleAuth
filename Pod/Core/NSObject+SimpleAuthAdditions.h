//
//  NSObject+SimpleAuthAdditions.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 1/20/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

static inline BOOL SimpleAuthClassIsSubclassOfClass(Class classOne, Class classTwo);

@interface NSObject (SimpleAuthAdditions)

+ (void)SimpleAuth_enumerateSubclassesWithBlock:(void (^) (Class klass, BOOL *stop))block;

@end
