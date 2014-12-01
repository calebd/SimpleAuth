//
//  SimpleAuthErrors.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/30/14.
//
//

#import <Foundation/Foundation.h>

/**
 Authentication error domain.
 */
extern NSString * const SimpleAuthErrorDomain;

/**
 The corresponding value is an HTTP staus code if the error was a network
 related error.
 */
extern NSString * const SimpleAuthErrorStatusCodeKey;

typedef NS_ENUM(NSUInteger, SimpleAuthError) {
    
    /**
     The user cancelled authentication.
     */
    SimpleAuthErrorUserCancelled,
    
    /*
     An error that occurred as the result of a failed network operation.
     */
    SimpleAuthErrorNetwork,
    
    /**
     An error that originated in Accounts.framework.
     */
    SimpleAuthErrorAccounts,
    
    /**
     Returned if SimpleAuth was able to parse response data.
     */
    SimpleAuthErrorInvalidData
};
