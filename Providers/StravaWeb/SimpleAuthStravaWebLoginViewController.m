//
//  SimpleAuthStravaWebLoginViewController.m
//  SimpleAuth
//
//  Created by Ben Stahl on 7/27/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthStravaWebLoginViewController.h"

@implementation SimpleAuthStravaWebLoginViewController


#pragma mark - SimpleAuthWebViewController

- (instancetype)initWithOptions:(NSDictionary *)options requestToken:(NSDictionary *)requestToken {
    if ((self = [super initWithOptions:options requestToken:requestToken])) {
        self.title = @"Strava";
    }
    return self;
}

- (NSURLRequest *)initialRequest {
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    parameters[@"client_id"] = self.options[@"client_id"];
    parameters[@"redirect_uri"] = self.options[SimpleAuthRedirectURIKey];
    parameters[@"response_type"] = @"code";
    if (self.options[@"scope"]) {
        parameters[@"scope"] = [self.options[@"scope"] componentsJoinedByString:@" "];
    }
    NSString *URLString = [NSString stringWithFormat:
                           @"https://www.strava.com/oauth/authorize?%@",
                           [CMDQueryStringSerialization queryStringWithDictionary:parameters]];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    return [NSURLRequest requestWithURL:URL];
}

@end
