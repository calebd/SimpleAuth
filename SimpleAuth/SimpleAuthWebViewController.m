//
//  SimpleAuthWebViewController.m
//  SimpleAuth
//
//  Created by Caleb on 11/7/13.
//  Copyright (c) 2013 SimpleAuth. All rights reserved.
//

#import "SimpleAuthWebViewController.h"

@implementation SimpleAuthWebViewController

@synthesize webView = _webView;

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.webView.frame = self.view.bounds;
    [self.view addSubview:self.webView];
}


#pragma mark - Public

- (instancetype)initWithConfiguration:(NSDictionary *)configuration {
    if ((self = [super init])) {
        _configuration = [configuration copy];
    }
    return self;
}


#pragma mark - Accessors

- (UIWebView *)webView {
    if (!_webView) {
        _webView = [UIWebView new];
        _webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        _webView.delegate = self;
    }
    return _webView;
}

@end
