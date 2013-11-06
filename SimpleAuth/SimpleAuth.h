//
//  SimpleAuth.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 SimpleAuth. All rights reserved.
//

#import "SimpleAuthConfiguration.h"

@interface SimpleAuth : NSObject

+ (SimpleAuthConfiguration *)configuration;

+ (void)authorize:(NSString *)provider completion:(void (^) (id response))completion;

@end
