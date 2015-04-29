//
//  SimpleAuthDribbbleLoginViewController.m
//  SimpleAuthInstagram
//
//  Created by Martin Pilch on 21/4/15.
//  Copyright (c) 2015 Martin Pilch, All rights reserved.
//

#import "SimpleAuthDribbbleLoginViewController.h"

@implementation SimpleAuthDribbbleLoginViewController

#pragma mark - SimpleAuthWebViewController

- (instancetype)initWithOptions:(NSDictionary *)options requestToken:(NSDictionary *)requestToken {
    if ((self = [super initWithOptions:options requestToken:requestToken])) {
        self.title = @"Dribbble";
    }
    return self;
}

- (NSURLRequest *)initialRequest {
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    parameters[@"client_id"] = self.options[@"client_id"];
    parameters[@"redirect_uri"] = self.options[SimpleAuthRedirectURIKey];
    if (self.options[@"scope"]) {
        parameters[@"scope"] = [self.options[@"scope"] componentsJoinedByString:@" "];
    }
    NSString *URLString = [NSString stringWithFormat:
                           @"https://dribbble.com/oauth/authorize?%@",
                           [CMDQueryStringSerialization queryStringWithDictionary:parameters]];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    return [NSURLRequest requestWithURL:URL];
}

@end
