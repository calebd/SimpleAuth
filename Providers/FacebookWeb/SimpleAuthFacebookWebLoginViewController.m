//
//  SimpleAuthFacebookWebLoginViewController.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 1/22/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthFacebookWebLoginViewController.h"
#import "SimpleAuth.h"

@interface SimpleAuthFacebookWebLoginViewController ()

@end

@implementation SimpleAuthFacebookWebLoginViewController

#pragma mark - UIViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSDictionary *parameters = @{
        @"client_id" : self.options[@"app_id"],
        @"redirect_uri" : self.options[SimpleAuthRedirectURIKey],
        @"response_type" : @"token"
    };
    NSString *URLString = [NSString stringWithFormat:
                           @"https://www.facebook.com/dialog/oauth?%@",
                           [CMDQueryStringSerialization queryStringWithDictionary:parameters]];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    [self.webView loadRequest:request];
}


#pragma mark - SimpleAuthWebViewController

- (instancetype)initWithOptions:(NSDictionary *)options requestToken:(NSDictionary *)requestToken {
    if ((self = [super initWithOptions:options requestToken:requestToken])) {
        self.title = @"Facebook";
    }
    return self;
}

@end
