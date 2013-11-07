//
//  SimpleAuthProvider.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 SimpleAuth. All rights reserved.
//

#import "SimpleAuth.h"

@interface SimpleAuthProvider : NSObject

+ (NSString *)type;

+ (SimpleAuthConfiguration *)configuration;

- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion;

@end
