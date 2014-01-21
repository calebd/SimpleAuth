//
//  SimpleAuthWebViewController.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/7/13.
//  Copyright (c) 2013-2014 Byliner, Inc. All rights reserved.
//

typedef void (^SimpleAuthWebViewControllerCompletionHandler) (UIViewController *controller, NSURL *URL, NSError *error);

@interface SimpleAuthWebViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, readonly) UIWebView *webView;
@property (nonatomic, readonly, copy) NSDictionary *options;
@property (nonatomic, copy) SimpleAuthWebViewControllerCompletionHandler completion;

- (instancetype)initWithOptions:(NSDictionary *)options;

- (BOOL)isTargetRedirectURL:(NSURL *)URL;

- (void)dismiss;

@end
