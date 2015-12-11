//
//  SimpleAuthConstantContactLoginViewController.m
//  SimpleAuth
//
//  Created by Tal Kain <tal@kain.net>.
//  Based on BoxWeb's provider created by dkhamsing and FoursquareWeb's provider created by Julien Seren-Rosso
//  Copyright (c) 2015 Fire Place Inc. All rights reserved.
//

#import "SimpleAuthConstantContactLoginViewController.h"
#import "SimpleAuthConstantContactConstants.h"

@implementation SimpleAuthConstantContactLoginViewController

#pragma mark - SimpleAuthWebViewController

- (instancetype)initWithOptions:(NSDictionary *)options requestToken:(NSDictionary *)requestToken {
    if ((self = [super initWithOptions:options requestToken:requestToken])) {
        self.title = @"ConstantContact";
    }
    return self;
}

- (NSURLRequest *)initialRequest {
    NSDictionary *parameters = @{
        @"client_id" : self.options[@"client_id"],
        @"redirect_uri" : self.options[SimpleAuthRedirectURIKey],
        @"response_type" : @"token"
    };
    NSString *URLString = [NSString stringWithFormat:@"%@?%@",
                           CONSTANT_CONTACT_AUTHORIZE_URI,
                           [CMDQueryStringSerialization queryStringWithDictionary:parameters]];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    return [NSURLRequest requestWithURL:URL];
}

@end
