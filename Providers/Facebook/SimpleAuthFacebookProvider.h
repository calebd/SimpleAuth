//
//  SimpleAuthFacebookProvider.h
//  SimpleAuthFacebook
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 Seesaw Decisions Corporation. All rights reserved.
//

#import "SimpleAuthSystemProvider.h"

@class RACSignal;

@interface SimpleAuthFacebookProvider : SimpleAuthSystemProvider

- (void)facebookAccountWithSystemAccount:(ACAccount *)account completion:(SimpleAuthRequestHandler)completion;

@end
