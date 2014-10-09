//
//  SimpleAuth.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013-2014 Byliner, Inc. All rights reserved.
//

extern NSString * const SimpleAuthErrorDomain;
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

/**
 Called when authentication completes with a response or fails with an error.
 Should an error occur, response object will be nil.
 
 @param responseObject The authorization response, or nil if an error occurred.
 @param error An error.
 */
typedef void (^SimpleAuthRequestHandler) (id responseObject, NSError *error);

extern NSString * const SimpleAuthPresentInterfaceBlockKey;
extern NSString * const SimpleAuthDismissInterfaceBlockKey;

/**
 Called when a user interface element must be presented to continue
 authentication. This could be a UIViewController for web login, or a
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
 */
+ (NSMutableDictionary *)configuration;

/**
 Perform authentication with the given provider and all previously configured
 and default provider options.
 
 @param provider A single provider type.
 @param completion Called on the main queue when the operation is complete.
 */
+ (void)authenticateWithProvider:(NSString * )provider completion:(SimpleAuthRequestHandler)completion;

/**
 Perform authentication with the given provider. Options provided here will
 be applied on top of any configured or default provider options.
 
 @param provider A single provider type.
 @param completion Called on the main queue when the operation is complete.
 */
+ (void)authenticateWithProvider:(NSString *)provider options:(NSDictionary *)options completion:(SimpleAuthRequestHandler)completion;

/**
 Perform authentication with the given providers. SimpleAuth will start
 authentication with the first provider in the list and will fall back
 through the given providers should an error occur.
 
 @param providers An array of provider types.
 @param completion Called on the main queue when the operation is complete.
 */
+ (void)authenticateWithProviders:(NSArray *)providers completion:(SimpleAuthRequestHandler)completion;

/**
 Perform authentication with the given providers. SimpleAuth will start
 authentication with the first provider in the list and will fall back
 through the given providers should an error occur. The options you
 provide here will be passed through to each provider in the providers list.
 
 @param providers An array of provider types.
 @param completion Called on the main queue when the operation is complete.
 */
+ (void)authenticateWithProviders:(NSArray *)providers options:(NSDictionary *)options completion:(SimpleAuthRequestHandler)completion;

/**
 Determine whether the provider can handle the callback URL or not. 
 
 @return A boolean specifying if the provider handles the specified URL.
 
 @param url The callback URL.
 */
+ (BOOL)handleCallback:(NSURL *)url;

+ (void)authorize:(NSString * )provider completion:(SimpleAuthRequestHandler)completion DEPRECATED_ATTRIBUTE;
+ (void)authorize:(NSString *)provider options:(NSDictionary *)options completion:(SimpleAuthRequestHandler)completion DEPRECATED_ATTRIBUTE;

@end
