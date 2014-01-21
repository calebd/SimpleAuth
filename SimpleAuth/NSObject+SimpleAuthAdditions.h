//
//  NSObject+SimpleAuthAdditions.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 1/20/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

@interface NSObject (SimpleAuthAdditions)

+ (void)SimpleAuth_enumerateSubclassesWithBlock:(void (^) (Class klass))block;
+ (void)SimpleAuth_enumerateSubclassesExcludingClasses:(NSSet *)set withBlock:(void (^) (Class klass))block;
+ (BOOL)SimpleAuth_isClass:(Class)klassOne subclassOfClass:(Class)klassTwo;

@end
