//
//  SimpleAuthFacebookProvider.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 SimpleAuth. All rights reserved.
//

#import "SimpleAuthSystemProvider.h"

@interface SimpleAuthFacebookProvider : SimpleAuthSystemProvider

- (void)facebookAccountWithSystemAccount:(ACAccount *)account completion:(SimpleAuthRequestHandler)completion;

@end
