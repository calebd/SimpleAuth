//
//  SimpleAuthTripItLoginViewController.m
//  SimpleAuth
//
//  Created by Mark Krenek on 8/15/14.
//  Copyright (c) 2014 Mark Krenek. All rights reserved.
//

#import "SimpleAuthTripItLoginViewController.h"

@implementation SimpleAuthTripItLoginViewController

#pragma mark - SimpleAuthWebViewController

- (instancetype)initWithOptions:(NSDictionary *)options requestToken:(NSDictionary *)requestToken {
    if ((self = [super initWithOptions:options requestToken:requestToken])) {
        self.title = @"TripIt";
    }
    return self;
}


- (NSURLRequest *)initialRequest {
    NSDictionary *parameters = @{
        @"oauth_token" : self.requestToken[@"oauth_token"],
        @"oauth_callback" : self.options[SimpleAuthRedirectURIKey],
    };
    NSString *URLString = [NSString stringWithFormat:
                           @"https://m.tripit.com/oauth/authorize?%@",
                           [CMDQueryStringSerialization queryStringWithDictionary:parameters]];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    return [NSURLRequest requestWithURL:URL];
}

@end
