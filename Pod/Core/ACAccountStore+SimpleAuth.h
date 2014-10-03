//
//  ACAccountStore+SimpleAuth.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 1/25/14.
//  Copyright (c) 2014 Seesaw Decisions Corporation. All rights reserved.
//

@import Accounts;
@class RACSignal;

@interface ACAccountStore (SimpleAuth)

/**
 Access a shared account store instance.
 
 @return A shared account store.
 */
+ (instancetype)SimpleAuth_sharedAccountStore;

/**
 Creates and returns a signal that sends next with all system accounts of the
 given type. This is a convenience wrapper for
 `-[ACAccountStore requestAccessToAccountsWithType:options:completion:]`.
 
 @return A signal that sends next with all system accounts of the given type.
 
 @param typeIdentifier Value passed to
 `-[ACAccountStore accountTypeWithAccountTypeIdentifier:]`
 @param options Value passed to
 `-[ACAccountStore requestAccessToAccountsWithType:options:completion:]`.
 */
+ (RACSignal *)SimpleAuth_accountsWithTypeIdentifier:(NSString *)typeIdentifier options:(NSDictionary *)options;

@end
