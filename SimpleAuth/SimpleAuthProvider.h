//
//  SimpleAuthProvider.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 SimpleAuth. All rights reserved.
//

@interface SimpleAuthProvider : NSObject

+ (NSString *)type;

+ (void)authorizeWithOptions:(NSDictionary *)options completion:(void (^) (id response))completion;

@end
