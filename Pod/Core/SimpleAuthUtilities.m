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
    NSBundle *mainBundle = [NSBundle bundleForClass:[SimpleAuth class]];
    NSURL *resourcesBundleURL = [mainBundle URLForResource:@"SimpleAuth" withExtension:@"bundle"];
    NSBundle *resourcesBundle = [NSBundle bundleWithURL:resourcesBundleURL];
    return NSLocalizedStringFromTableInBundle(key, nil, resourcesBundle, nil);
}
