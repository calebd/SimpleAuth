//
//  SimpleAuth.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 Seesaw Decisions Corporation. All rights reserved.
//

typedef void (^SimpleAuthRequestHandler) (id responseObject, NSHTTPURLResponse *response, NSError *error);

@interface SimpleAuth : NSObject

/**
 
 */
+ (NSMutableDictionary *)configuration;

/**
 
 */
+ (void)registerProviderClass:(Class)klass;

/**
 
 */
+ (void)authorize:(NSString *)provider completion:(SimpleAuthRequestHandler)completion;

/**
 
 */
+ (void)authorize:(NSString *)provider options:(NSDictionary *)options completion:(SimpleAuthRequestHandler)completion;

@end
