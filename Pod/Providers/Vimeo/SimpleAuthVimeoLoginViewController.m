//
//  SimpleAuthVimeoLoginViewController.m
//  SimpleAuthVimeo
//
//  Created by Martin Pilch on 21/4/15.
//  Copyright (c) 2015 Martin Pilch, All rights reserved.
//

#import "SimpleAuthVimeoLoginViewController.h"

@implementation SimpleAuthVimeoLoginViewController

#pragma mark - SimpleAuthWebViewController

- (instancetype)initWithOptions:(NSDictionary *)options requestToken:(NSDictionary *)requestToken {
    if ((self = [super initWithOptions:options requestToken:requestToken])) {
        self.title = @"Vimeo";
    }
    return self;
}


- (NSURLRequest *)initialRequest {
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    parameters[@"client_id"] = self.options[@"client_id"];
    parameters[@"redirect_uri"] = self.options[SimpleAuthRedirectURIKey];
    parameters[@"response_type"] = @"code";
    parameters[@"state"] = self.options[@"state"];
    if (self.options[@"scope"]) {
        parameters[@"scope"] = [self.options[@"scope"] componentsJoinedByString:@" "];
    }
    NSString *URLString = [NSString stringWithFormat:
                           @"https://api.vimeo.com/oauth/authorize?%@",
                           [CMDQueryStringSerialization queryStringWithDictionary:parameters]];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    return [NSURLRequest requestWithURL:URL];
}

@end
