//
//  SimpleAuthLinkedInWebLoginViewController.m
//  SimpleAuth
//
//  Created by Abhishek Sheth on 24/01/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthLinkedInWebLoginViewController.h"

@interface SimpleAuthLinkedInWebLoginViewController ()

@end

@implementation SimpleAuthLinkedInWebLoginViewController

#pragma mark - SimpleAuthWebViewController

- (instancetype)initWithOptions:(NSDictionary *)options requestToken:(NSDictionary *)requestToken {
    if ((self = [super initWithOptions:options requestToken:requestToken])) {
        self.title = @"LinkedIn";
    }
    return self;
}


- (NSURLRequest *)initialRequest {
    NSDictionary *parameters = @{
        @"client_id" : self.options[@"client_id"],
        @"redirect_uri" : self.options[SimpleAuthRedirectURIKey],
        @"response_type" : @"code",
        @"state" : [[NSProcessInfo processInfo] globallyUniqueString]
    };
    
    NSString *URLString = [NSString stringWithFormat:
                           @"https://www.linkedin.com/uas/oauth2/authorization?%@",
                           [CMDQueryStringSerialization queryStringWithDictionary:parameters]];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    return [NSURLRequest requestWithURL:URL];
}



@end
