//
//  SimpleAuthSystemProvider.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 SimpleAuth. All rights reserved.
//

#import "SimpleAuthProvider.h"

@class ACAccountStore;

@interface SimpleAuthSystemProvider : SimpleAuthProvider

+ (ACAccountStore *)accountStore;

@end
