//
//  SimpleAuthDefines.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/30/14.
//  Copyright (c) 2013-2015 Caleb Davenport. All rights reserved.
//

@import Foundation;

/**
 Authentication error domain.
 */
extern NSString *const SimpleAuthErrorDomain;

/**
 The corresponding value is an HTTP staus code if the error was a network
 related error.
 */
extern NSString *const SimpleAuthErrorStatusCodeKey;

/**
 Error codes for errors in the `SimpleAuthErrorDomain`.
 */
typedef NS_ENUM(NSUInteger, SimpleAuthError) {
    
    /**
     The user cancelled authentication.
     */
    SimpleAuthErrorUserCancelled = 100,
    
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

/**
 Called when authorization either completes with a response or fails with an
 error. Should an error occur, response object will be nil.

 @param responseObject The authorization response, or nil if an error occurred.
 @param error An error.

 @see +authorize:completion:
 @see +authorize:options:completion:
 */
typedef void (^SimpleAuthRequestHandler) (id responseObject, NSError *error);

extern NSString *const SimpleAuthPresentInterfaceBlockKey;
extern NSString *const SimpleAuthDismissInterfaceBlockKey;

/**
 Called when a user interface element must be presented to continue
 authorization. This could be a UIViewController for web login, or a
 UIActionSheet for system login. All providers will have default
 implementations for the appropriate callback types. You can customize provider
 behavior by providing your own blocks.  This will be called on the main
 thread.

 @see SimpleAuthPresentInterfaceBlockKey
 @see SimpleAuthDismissInterfaceBlockKey
 @see +configuration
 @see +authorize:options:completion:

 @param userInterfaceElement An element that is about to be presented or
 dismissed.
 */
typedef void (^SimpleAuthInterfaceHandler) (id userInterfaceElement);

/**
 Key used to define the redirect URI for OAuth style providers.

 @see +configuration
 @see +authorize:options:completion:
 */
extern NSString *const SimpleAuthRedirectURIKey;
