//
//  SimpleAuthWebViewController.h
//  SimpleAuth
//
//  Created by Caleb on 11/7/13.
//  Copyright (c) 2013 SimpleAuth. All rights reserved.
//

@interface SimpleAuthWebViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, readonly) UIWebView *webView;
@property (nonatomic, readonly) NSDictionary *configuration;

- (id)initWithConfiguration:(NSDictionary *)configuration;

@end
