//
//  SimpleAuthFlickrWebLoginViewController.m
//  SimpleAuth
//
//  Created by David Caunt on 29/06/2014.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthFlickrWebLoginViewController.h"

@implementation SimpleAuthFlickrWebLoginViewController

#pragma mark - SimpleAuthWebViewController

- (instancetype)initWithOptions:(NSDictionary *)options requestToken:(NSDictionary *)requestToken {
    if ((self = [super initWithOptions:options requestToken:requestToken])) {
        self.title = @"Flickr";
    }
    return self;
}


- (NSURLRequest *)initialRequest {
    NSDictionary *parameters = @{
        @"oauth_token": self.requestToken[@"oauth_token"],
        @"perms": self.options[@"perms"]
    };
    NSString *URLString = [NSString stringWithFormat:
                           @"https://www.flickr.com/services/oauth/authorize?%@",
                           [CMDQueryStringSerialization queryStringWithDictionary:parameters]];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    return [NSURLRequest requestWithURL:URL];
}

@end
