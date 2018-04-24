//
//  SimpleAuthWebViewController.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/7/13.
//  Copyright (c) 2013-2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthWebViewController.h"

@interface SimpleAuthWebViewController ()

@property (nonatomic, copy) NSDictionary *options;
@property (nonatomic, copy) NSDictionary *requestToken;

@end

@implementation SimpleAuthWebViewController {
    BOOL _hasInitialLoad;
}

@synthesize webView = _webView;

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupWebView];
}

- (void)setupWebView {
    [self.view addSubview:self.webView];
    
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.webView.topAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.topAnchor].active = YES;
    [self.webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [self.webView.bottomAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.bottomAnchor].active = YES;
    [self.webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!_hasInitialLoad) {
        _hasInitialLoad = YES;
        NSURLRequest *request = [self initialRequest];
        request = [[self class] canonicalRequestForRequest:request];
        [self.webView loadRequest:request];
    }
}


#pragma mark - Public

- (instancetype)initWithOptions:(NSDictionary *)options requestToken:(NSDictionary *)requestToken {
    if ((self = [super init])) {
        self.options = options;
        self.requestToken = requestToken;
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                 initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                 target:self
                                                 action:@selector(cancel)];
    }
    return self;
}


- (instancetype)initWithOptions:(NSDictionary *)options {
    self = [self initWithOptions:options requestToken:nil];
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


- (void)cancel {
    NSError *error = [NSError errorWithDomain:SimpleAuthErrorDomain code:SimpleAuthErrorUserCancelled userInfo:nil];
    self.completion(self, nil, error);
}


- (NSURLRequest *)initialRequest {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}


#pragma mark - Private

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    [mutableRequest setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    return mutableRequest;
}


#pragma mark - Accessors

- (UIWebView *)webView {
    if (!_webView) {
        _webView = [UIWebView new];
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
