//
//  SimpleAuthInstagramLoginViewController.m
//  SimpleAuthInstagram
//
//  Created by Caleb Davenport on 11/7/13.
//  Copyright (c) 2013 Seesaw Decisions Corporation. All rights reserved.
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
        @"redirect_uri" : self.options[@"redirect_uri"],
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
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                 initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                 target:self
                                                 action:@selector(close)];
    }
    return self;
}


- (id)responseObjectFromRedirectURL:(NSURL *)URL {
    NSString *response = [URL fragment] ?: [URL query];
    return [NSDictionary sam_dictionaryWithFormEncodedString:response];
}


#pragma mark - Actions

- (void)close {
    SimpleAuthInterfaceHandler block = self.options[@"dismiss_interface_block"];
    block(self);
}

@end
