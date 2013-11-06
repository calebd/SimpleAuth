//
//  SimpleAuth_private.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 SimpleAuth. All rights reserved.
//

#import "SimpleAuth.h"

@interface SimpleAuth (Internal)

+ (void)registerProviderClass:(Class)klass;

@end
