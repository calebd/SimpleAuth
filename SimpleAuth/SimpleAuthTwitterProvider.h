//
//  SimpleAuthTwitterProvider.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 SimpleAuth. All rights reserved.
//

#import "SimpleAuthSystemProvider.h"

@interface SimpleAuthTwitterProvider : SimpleAuthSystemProvider

- (void)requestTokenWithParameters:(NSDictionary *)parameters completion:(SimpleAuthRequestHandler)completion;

- (void)reverseAuthRequestToken:(SimpleAuthRequestHandler)completion;

- (void)accessTokenWithReverseAuthRequestToken:(NSString *)token account:(ACAccount *)account completion:(SimpleAuthRequestHandler)completion;

@end
