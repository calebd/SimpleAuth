//
//  SimpleAuth.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 SimpleAuth. All rights reserved.
//

typedef void (^SimpleAuthRequestHandler) (id responseObject, NSHTTPURLResponse *response, NSError *error);

@interface SimpleAuth : NSObject

+ (NSMutableDictionary *)configuration;

+ (void)authorize:(NSString *)provider completion:(SimpleAuthRequestHandler)completion;

@end
