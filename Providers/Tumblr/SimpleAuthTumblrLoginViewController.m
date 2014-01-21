//
//  SimpleAuthTumblrLoginViewController.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 1/16/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthTumblrLoginViewController.h"

#import <SAMCategories/NSDictionary+SAMAdditions.h>

@interface SimpleAuthTumblrLoginViewController ()

@property (nonatomic, copy) NSDictionary *requestToken;

@end

@implementation SimpleAuthTumblrLoginViewController

#pragma mark - UIViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSDictionary *parameters = @{
        @"oauth_token" : self.requestToken[@"oauth_token"],
    };
    NSString *URLString = [NSString stringWithFormat:
                           @"http://www.tumblr.com/oauth/authorize?%@",
                           [parameters sam_stringWithFormEncodedComponents]];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    [self.webView loadRequest:request];
}


#pragma mark - Public

- (instancetype)initWithOptions:(NSDictionary *)options requestToken:(NSDictionary *)requestToken {
    if ((self = [super initWithOptions:options])) {
        self.requestToken = requestToken;
        self.title = @"tumblr";
    }
    return self;
}

@end
