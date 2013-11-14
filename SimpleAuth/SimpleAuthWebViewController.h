//
//  SimpleAuthWebViewController.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/7/13.
//  Copyright (c) 2013 Seesaw Decisions Corporation. All rights reserved.
//

typedef void (^SimpleAuthWebViewControllerCompletionHandler) (id responseObject, NSError *error);

@interface SimpleAuthWebViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, readonly) UIWebView *webView;
@property (nonatomic, readonly) NSDictionary *options;
@property (nonatomic, copy) SimpleAuthWebViewControllerCompletionHandler completion;

- (instancetype)initWithOptions:(NSDictionary *)options;

- (BOOL)isTargetRedirectURL:(NSURL *)URL;
- (id)responseObjectFromRedirectURL:(NSURL *)URL;

@end
