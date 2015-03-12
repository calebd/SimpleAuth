//
//  SimpleAuthWebViewController.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/7/13.
//  Copyright (c) 2013-2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuth.h"

#import <CMDQueryStringSerialization/CMDQueryStringSerialization.h>

typedef void (^SimpleAuthWebViewControllerCompletionHandler) (UIViewController *controller, NSURL *URL, NSError *error);

@interface SimpleAuthWebViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, readonly) UIWebView *webView;
@property (nonatomic, readonly, copy) NSDictionary *options;
@property (nonatomic, readonly, copy) NSDictionary *requestToken;
@property (nonatomic, copy) SimpleAuthWebViewControllerCompletionHandler completion;

/**
 Initializes a basic web login view controller.
 @param options Providers should pass their options along here.
 @see -initWithOptions:requestToken:
 */
- (instancetype)initWithOptions:(NSDictionary *)options;

/**
 Initializes a web login view controller for an OAuth 1 style provider.
 @param options Providers should pass their options along here.
 @param requestToken Token obtained through the OAuth 1 flow.
 @see -initWithOptions:
 */
- (instancetype)initWithOptions:(NSDictionary *)options requestToken:(NSDictionary *)requestToken;

/**
 Subclasses should override this to provide the request that will be loaded the
 first time that the web view appears.
 @return A URL request.
 */
- (NSURLRequest *)initialRequest;

/**
 Subclasses may override this to determine if the a given URL is the desired
 redirect URL. The default implementation of this method checks the given URL
 agains the value provided in options.
 @param URL The URL to inspect.
 @return `YES` if the URL is the desired redirect URL, `NO` if it is not.
 */
- (BOOL)isTargetRedirectURL:(NSURL *)URL;

@end
