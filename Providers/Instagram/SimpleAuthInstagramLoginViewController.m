//
//  SimpleAuthInstagramLoginViewController.m
//  SimpleAuthInstagram
//
//  Created by Caleb Davenport on 11/7/13.
//  Copyright (c) 2013-2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthInstagramLoginViewController.h"
#import "SimpleAuth.h"

#import <SAMCategories/NSDictionary+SAMAdditions.h>

@interface SimpleAuthInstagramLoginViewController ()

@end

@implementation SimpleAuthInstagramLoginViewController

#pragma mark - UIViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSDictionary *parameters = @{
        @"client_id" : self.options[@"client_id"],
        @"redirect_uri" : self.options[SimpleAuthRedirectURIKey],
        @"response_type" : @"token"
    };
    NSString *URLString = [NSString stringWithFormat:
                           @"https://instagram.com/oauth/authorize/?%@",
                           [parameters sam_stringWithFormEncodedComponents]];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    [self.webView loadRequest:request];
}

#pragma mark - SimpleAuthWebViewController

- (instancetype)initWithOptions:(NSDictionary *)options {
    if ((self = [super initWithOptions:options])) {
        self.title = @"Instagram";
    }
    return self;
}

@end
