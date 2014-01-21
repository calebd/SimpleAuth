//
//  SimpleAuthWebViewController.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/7/13.
//  Copyright (c) 2013-2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthWebViewController.h"
#import "SimpleAuth.h"

@interface SimpleAuthWebViewController ()

@property (nonatomic, copy) NSDictionary *options;

@end

@implementation SimpleAuthWebViewController

@synthesize webView = _webView;

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.webView.frame = self.view.bounds;
    [self.view addSubview:self.webView];
}


#pragma mark - Public

- (instancetype)initWithOptions:(NSDictionary *)options {
    if ((self = [super init])) {
        self.options = options;
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                 initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                 target:self
                                                 action:@selector(dismiss)];
    }
    return self;
}


- (BOOL)isTargetRedirectURL:(NSURL *)URL {
    NSString *targetURLString = [self.options[SimpleAuthRedirectURIKey] lowercaseString];
    NSString *actualURLString = [[URL absoluteString] lowercaseString];
    return [actualURLString hasPrefix:targetURLString];
}


- (id)responseObjectFromRedirectURL:(NSURL *)URL {
    return nil;
}


- (void)dismiss {
    SimpleAuthInterfaceHandler block = self.options[SimpleAuthDismissInterfaceBlockKey];
    block(self);
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
    self.completion(self, nil, error);
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)type {
    NSURL *URL = [request URL];
    if ([self isTargetRedirectURL:URL]) {
        webView.delegate = nil;
        self.completion(self, URL, nil);
        return NO;
    }
    return YES;
}

@end
