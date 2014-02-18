//
//  SimpleAuthSinaWeiboWebLoginViewController.m
//  SimpleAuth
//
//  Created by Alexander Schuch on 17/02/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthSinaWeiboWebLoginViewController.h"

@interface SimpleAuthSinaWeiboWebLoginViewController ()

@end

@implementation SimpleAuthSinaWeiboWebLoginViewController

#pragma mark - SimpleAuthWebViewController

- (instancetype)initWithOptions:(NSDictionary *)options requestToken:(NSDictionary *)requestToken {
    if ((self = [super initWithOptions:options requestToken:requestToken])) {
        self.title = @"Sina Weibo";
    }
    return self;
}


- (NSURLRequest *)initialRequest {
	NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];

    NSDictionary *parameters = @{
								 @"client_id" : self.options[@"client_id"],
								 @"redirect_uri" : self.options[SimpleAuthRedirectURIKey],
								 @"state" : [[NSProcessInfo processInfo] globallyUniqueString],
								 @"display": @"mobile",
								 @"language": language
								 };
    
	NSString *parameterString = [CMDQueryStringSerialization queryStringWithDictionary:parameters];
    NSString *URLString = [NSString stringWithFormat:@"https://api.weibo.com/oauth2/authorize?%@", parameterString];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    return [NSURLRequest requestWithURL:URL];
}

@end
