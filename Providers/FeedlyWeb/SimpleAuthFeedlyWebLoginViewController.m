//
//  SimpleAuthFeedlyWebLoginViewController.m
//  SimpleAuth
//
//  Created by Luís Portela Afonso on 26/02/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthFeedlyWebLoginViewController.h"


@implementation SimpleAuthFeedlyWebLoginViewController

- (id)initWithOptions:(NSDictionary *)options requestToken:(NSDictionary *)requestToken {
    if ((self = [super initWithOptions:options requestToken:requestToken])) {
        self.title = @"Feedly";
    }
    return self;
}


- (NSURLRequest *)initialRequest {
    NSDictionary *parameters = @{
								 @"response_type" : @"code",
								 @"client_id" : self.options[@"client_id"],
								 @"redirect_uri" : self.options[@"redirect_uri"],
								 @"scope" : (self.options[@"scope"] != nil ? self.options[@"code"] : @"https://cloud.feedly.com/subscriptions"),
								 @"state" : (self.options[@"state"] != nil ? self.options[@"state"] : @"state.passed.in")
								 };
	NSString *URLString = [NSString stringWithFormat:@"http://feedly.com/v3/auth/auth?%@", [CMDQueryStringSerialization queryStringWithDictionary:parameters]];
    
    return [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
}

@end
