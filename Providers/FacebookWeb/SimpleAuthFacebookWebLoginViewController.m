//
//  SimpleAuthFacebookWebLoginViewController.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 1/22/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthFacebookWebLoginViewController.h"

@implementation SimpleAuthFacebookWebLoginViewController

#pragma mark - SimpleAuthWebViewController

- (instancetype)initWithOptions:(NSDictionary *)options requestToken:(NSDictionary *)requestToken {
    if ((self = [super initWithOptions:options requestToken:requestToken])) {
        self.title = @"Facebook";
    }
    return self;
}


- (NSURLRequest *)initialRequest {
    NSDictionary *parameters = @{
        @"client_id" : self.options[@"app_id"],
        @"redirect_uri" : self.options[SimpleAuthRedirectURIKey],
        @"response_type" : @"token",
        @"scope" : [self.options[@"permissions"] componentsJoinedByString:@","]
    };
    NSString *URLString = [NSString stringWithFormat:
                           @"https://www.facebook.com/dialog/oauth?%@",
                           [CMDQueryStringSerialization queryStringWithDictionary:parameters]];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    return [NSURLRequest requestWithURL:URL];
}

@end
