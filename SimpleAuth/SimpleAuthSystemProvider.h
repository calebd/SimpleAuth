//
//  SimpleAuthSystemProvider.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 Seesaw Decisions Corporation. All rights reserved.
//

#import "SimpleAuthProvider.h"

@import Accounts;
@import Social;

typedef void (^SimpleAuthSystemAccountHandler) (ACAccount *account, NSError *error);

@interface SimpleAuthSystemProvider : SimpleAuthProvider

+ (ACAccountStore *)accountStore;

- (void)loadSystemAccount:(SimpleAuthSystemAccountHandler)completion;

- (void)authorizeWithSystemAccount:(ACAccount *)account completion:(SimpleAuthRequestHandler)completion;

@end
