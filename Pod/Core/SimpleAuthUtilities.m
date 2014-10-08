//
//  SimpleAuthUtilities.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 10/7/14.
//  Copyright (c) 2013-2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthUtilities.h"
#import "SimpleAuth.h"

NSString *SimpleAuthLocalizedString(NSString *key) {
    NSURL *URL = [[NSBundle mainBundle] URLForResource:@"SimpleAuth" withExtension:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithURL:URL];
    return [bundle localizedStringForKey:key value:nil table:@"SimpleAuth"];
}
