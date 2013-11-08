//
//  SimpleAuthInstagramViewController.m
//  SimpleAuth
//
//  Created by Caleb on 11/7/13.
//  Copyright (c) 2013 SimpleAuth. All rights reserved.
//

#import "SimpleAuthInstagramLoginViewController.h"

#import <SAMCategories/NSDictionary+SAMAdditions.h>

@interface SimpleAuthInstagramLoginViewController ()

@end

@implementation SimpleAuthInstagramLoginViewController

#pragma mark - UIViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSDictionary *parameters = @{
        @"client_id" : self.configuration[@"client_id"],
        @"redirect_uri" : self.configuration[@"redirect_uri"],
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

- (instancetype)initWithConfiguration:(NSDictionary *)configuration {
    if ((self = [super initWithConfiguration:configuration])) {
        self.title = @"Instagram";
    }
    return self;
}


- (id)responseObjectFromRedirectURL:(NSURL *)URL {
    NSString *response = [URL fragment] ?: [URL query];
    return [NSDictionary sam_dictionaryWithFormEncodedString:response];
}

@end
