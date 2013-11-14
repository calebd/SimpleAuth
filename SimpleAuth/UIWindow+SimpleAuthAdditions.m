//
//  UIWindow+SimpleAuthAdditions.m
//  SimpleAuth
//
//  Created by Caleb on 11/14/13.
//  Copyright (c) 2013 Seesaw Decisions Corporation. All rights reserved.
//

#import "UIWindow+SimpleAuthAdditions.h"

@implementation UIWindow (SimpleAuthAdditions)

+ (instancetype)sa_mainWindow {
    return [[[UIApplication sharedApplication] delegate] window];
}

@end
