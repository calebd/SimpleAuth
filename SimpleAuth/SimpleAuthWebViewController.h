//
//  SimpleAuthWebViewController.h
//  SimpleAuth
//
//  Created by Caleb on 11/7/13.
//  Copyright (c) 2013 SimpleAuth. All rights reserved.
//

typedef void (^SimpleAuthWebViewControllerCompletionHandler) (id responseObject, NSError *error);

@interface SimpleAuthWebViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, readonly) UIWebView *webView;
@property (nonatomic, readonly) NSDictionary *configuration;
@property (nonatomic, copy) SimpleAuthWebViewControllerCompletionHandler completion;

- (id)initWithConfiguration:(NSDictionary *)configuration;

- (BOOL)isTargetRedirectURL:(NSURL *)URL;
- (id)responseObjectFromRedirectURL:(NSURL *)URL;

@end
