//
//  SimpleAuthProvider.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 Seesaw Decisions Corporation. All rights reserved.
//

#import "SimpleAuth.h"

@interface SimpleAuthProvider : NSObject

/**
 
 */
@property (nonatomic, readonly) NSDictionary *options;

/**
 
 */
+ (NSString *)type;

/**
 
 */
+ (NSDictionary *)defaultOptions;

/**
 Default initializer. Create a provider with the given options.
 @param options The options used to configure the receiver.
 @return A provider object.
 @see -options
 */
- (instancetype)initWithOptions:(NSDictionary *)options;

/**
 
 */
- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion;

@end
