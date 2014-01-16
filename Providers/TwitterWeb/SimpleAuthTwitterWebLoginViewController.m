//
//  SimpleAuthTwitterWebLoginViewController.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 1/15/14.
//  Copyright (c) 2014 Seesaw Decisions Corporation. All rights reserved.
//

#import "SimpleAuthTwitterWebLoginViewController.h"

#import <SAMCategories/NSDictionary+SAMAdditions.h>

@interface SimpleAuthTwitterWebLoginViewController ()

@property (nonatomic, copy) NSDictionary *requestToken;

@end

@implementation SimpleAuthTwitterWebLoginViewController

#pragma mark - UIViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSDictionary *parameters = @{
        @"oauth_token" : self.requestToken[@"oauth_token"],
    };
    NSString *URLString = [NSString stringWithFormat:
                           @"https://api.twitter.com/oauth/authenticate?%@",
                           [parameters sam_stringWithFormEncodedComponents]];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    [self.webView loadRequest:request];
}


#pragma mark - Public

- (instancetype)initWithOptions:(NSDictionary *)options requestToken:(NSDictionary *)requestToken {
    if ((self = [super initWithOptions:options])) {
        self.requestToken = requestToken;
        self.title = @"Twitter";
    }
    return self;
}

@end
