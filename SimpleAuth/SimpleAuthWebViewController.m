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


- (BOOL)isTargetRedirectURL:(NSURL *)URL {
    NSString *targetURLString = [self.configuration[@"redirect_uri"] lowercaseString];
    NSString *actualURLString = [[URL absoluteString] lowercaseString];
    return [actualURLString hasPrefix:targetURLString];
}


- (id)responseObjectFromRedirectURL:(NSURL *)URL {
    return nil;
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


#pragma mark - UIWebViewDelegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    webView.delegate = nil;
    if (self.completion) {
        self.completion(nil, nil, error);
    }
    self.completion = nil;
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)type {
    NSURL *URL = [request URL];
    if ([self isTargetRedirectURL:URL]) {
        webView.delegate = nil;
        if (self.completion) {
            id responseObject = [self responseObjectFromRedirectURL:URL];
            self.completion(responseObject, nil, nil);
        }
        return NO;
    }
    return YES;
}

@end
