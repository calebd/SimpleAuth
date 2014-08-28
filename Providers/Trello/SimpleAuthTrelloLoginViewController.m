//
//  SimpleAuthTrelloLoginViewController.m
//  SimpleAuth
//
//  Created by Damiano Buscemi on 22/08/14.
//  Copyright (c) 2014 Crispy Bacon, S.r.l. All rights reserved.
//

#import "SimpleAuthTrelloLoginViewController.h"

@interface SimpleAuthTrelloLoginViewController ()

@end

@implementation SimpleAuthTrelloLoginViewController

#pragma mark - SimpleAuthWebViewController

- (instancetype)initWithOptions:(NSDictionary *)options requestToken:(NSDictionary *)requestToken {
    if ((self = [super initWithOptions:options requestToken:requestToken])) {
        self.title = @"Trello";
    }
    return self;
}


- (NSURLRequest *)initialRequest {
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    parameters[@"key"] = self.options[@"key"];
    parameters[@"response_type"] = @"token";
    parameters[@"expiration"] = @"30days";
    parameters[@"callback_method"] = @"fragment";
    parameters[@"return_url"] = self.options[SimpleAuthRedirectURIKey];
    parameters[@"name"] = self.options[@"name"];
    if (self.options[@"scope"]) {
        parameters[@"scope"] = [self.options[@"scope"] componentsJoinedByString:@" "];
    }
    NSString *URLString = [NSString stringWithFormat:
                           @"https://trello.com/1/authorize/?%@",
                           [CMDQueryStringSerialization queryStringWithDictionary:parameters]];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    return [NSURLRequest requestWithURL:URL];
}

@end
