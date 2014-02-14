//
//  SimpleAuth.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013-2014 Byliner, Inc. All rights reserved.
//

extern NSString * const SimpleAuthErrorDomain;
enum {
    SimpleAuthErrorUserCancelled
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

extern NSString * const SimpleAuthPresentInterfaceBlockKey;
extern NSString * const SimpleAuthDismissInterfaceBlockKey;

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
extern NSString * const SimpleAuthRedirectURIKey;

extern NSString * const SimpleAuthBeginActivityBlockKey;
extern NSString * const SimpleAuthEndActivityBlockKey;

@interface SimpleAuth : NSObject

/**
 Set options used to configure each provider. Things like access tokens and
 OAuth redirect URLs should be set here. Every provider should document the 
 options that it accepts. These options override a provider's default options,
 and options passed to +authorize:options:completion: likewise override these.
 
 @return A mutable dictionary whose string keys correspond to provider types
 and values are dictionaries that are passed on to a provider during an
 authorization operation.
 
 @see +authorize:options:completion:
 */
+ (NSMutableDictionary *)configuration;

/**
 Perform authorization with the given provider and all previously configured
 and default provider options.
 
 @param completion Called on the main queue when the operation is complete.
 
 @see +authorize:options:completion:
 */
+ (void)authorize:(NSString *)provider completion:(SimpleAuthRequestHandler)completion;

/**
 Perform an authorization with the given provider. Options provided here will
 be applied on top of any configured or default provider options.
 
 @param completion Called on the main queue when the operation is complete.
 
 @see +configuration
 @see +authorize:completion:
 */
+ (void)authorize:(NSString *)provider options:(NSDictionary *)options completion:(SimpleAuthRequestHandler)completion;

/**
 Determine whether the provider can handle the callback URL or not. 
 
 @return A boolean specifying if the provider handles the specified URL.
 
 @param url The callback URL.
 */
+ (BOOL)handleCallback:(NSURL *)url;

@end
