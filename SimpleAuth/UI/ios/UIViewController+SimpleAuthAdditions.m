//
//  UIViewController+SimpleAuthAdditions.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/14/13.
//  Copyright (c) 2013-2014 Byliner, Inc. All rights reserved.
//

#import "UIViewController+SimpleAuthAdditions.h"
#import "UIWindow+SimpleAuthAdditions.h"

@implementation UIViewController (SimpleAuthAdditions)

+ (instancetype)SimpleAuth_presentedViewController {
    UIWindow *window = [UIWindow SimpleAuth_mainWindow];
    UIViewController *controller = window.rootViewController;
    while (controller.presentedViewController) {
        controller = controller.presentedViewController;
    }
    return controller;
}

@end
