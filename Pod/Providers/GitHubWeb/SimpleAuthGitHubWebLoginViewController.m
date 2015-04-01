//
//  SimpleAuthGitHubLoginViewController.m
//  SimpleAuth
//
//  Created by dkhamsing on 3/26/15.
//  Copyright (c) 2015 dkhamsing. All rights reserved.
//

#import "SimpleAuthGitHubWebLoginViewController.h"

@implementation SimpleAuthGitHubWebLoginViewController

#pragma mark - SimpleAuthWebViewController

- (instancetype)initWithOptions:(NSDictionary *)options requestToken:(NSDictionary *)requestToken {
    if ((self = [super initWithOptions:options requestToken:requestToken])) {
        self.title = @"GitHub";
    }
    return self;
}


- (NSURLRequest *)initialRequest {
    NSDictionary *parameters = @{
        @"client_id" : self.options[@"client_id"],
        @"response_type" : @"code",
        @"scope": self.options[@"scope"]
    };
    NSString *URLString = [NSString stringWithFormat:
                           @"https://github.com/login/oauth/authorize?%@",
                           [CMDQueryStringSerialization queryStringWithDictionary:parameters]];
    
    NSURL *URL = [NSURL URLWithString:URLString];
    
    return [NSURLRequest requestWithURL:URL];
}


- (BOOL)isTargetRedirectURL:(NSURL *)URL {
    NSRange range = [URL.absoluteString rangeOfString:@"?code=" options:NSCaseInsensitiveSearch];
    return range.location != NSNotFound;
}


@end
