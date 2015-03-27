//
//  SimpleAuthBoxWebLoginViewController.m
//  SimpleAuth
//
//  Created by dkhamsing on 3/26/15.
//  Copyright (c) 2015 dkhamsing. All rights reserved.
//

#import "SimpleAuthBoxWebLoginViewController.h"

@implementation SimpleAuthBoxWebLoginViewController

#pragma mark - SimpleAuthWebViewController

- (instancetype)initWithOptions:(NSDictionary *)options requestToken:(NSDictionary *)requestToken {
    NSMutableDictionary *optionsCopy = options.mutableCopy;
    optionsCopy[SimpleAuthRedirectURIKey] = [NSString stringWithFormat:@"boxsdk-%@://boxsdkoauth2redirect", options[@"client_id"]];    
    if ((self = [super initWithOptions:optionsCopy.copy requestToken:requestToken])) {
        self.title = @"Box";
    }
    return self;
}


- (NSURLRequest *)initialRequest {
    NSDictionary *parameters = @{
        @"client_id" : self.options[@"client_id"],
        @"redirect_uri" : [NSString stringWithFormat:@"boxsdk-%@://boxsdkoauth2redirect", self.options[@"client_id"]],
        @"response_type" : @"code"
    };
    NSString *URLString = [NSString stringWithFormat:
                           @"https://api.box.com/oauth2/authorize?%@",
                           [CMDQueryStringSerialization queryStringWithDictionary:parameters]];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    return [NSURLRequest requestWithURL:URL];
}

@end
