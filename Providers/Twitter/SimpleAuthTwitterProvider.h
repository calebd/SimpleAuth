//
//  SimpleAuthTwitterProvider.h
//  SimpleAuthTwitter
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 Seesaw Decisions Corporation. All rights reserved.
//

#import "SimpleAuthSystemProvider.h"

@class RACSignal;

@interface SimpleAuthTwitterProvider : SimpleAuthSystemProvider

- (RACSignal *)allTwitterAccounts;
- (RACSignal *)selectedTwitterAccount;
- (RACSignal *)twitterAccountFromAccounts:(NSArray *)accounts;

- (RACSignal *)requestTokenWithParameters:(NSDictionary *)parameters;

- (RACSignal *)accessTokenWithAccount:(ACAccount *)account;

- (RACSignal *)twitterAccountWithAccount:(ACAccount *)account;

@end
