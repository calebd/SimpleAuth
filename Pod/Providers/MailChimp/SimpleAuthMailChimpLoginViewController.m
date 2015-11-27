//
//  SimpleAuthMailChimpLoginViewController.m
//  SimpleAuth
//
//  Created by Tal Kain <tal@kain.net>.
//  Based on BoxWeb's provider created by dkhamsing and FoursquareWeb's provider created by Julien Seren-Rosso
//  Copyright (c) 2015 Fire Place Inc. All rights reserved.
//

#import "SimpleAuthMailChimpLoginViewController.h"
#import "SimpleAuthMailChimpConstants.h"

@implementation SimpleAuthMailChimpLoginViewController

#pragma mark - SimpleAuthWebViewController

- (instancetype)initWithOptions:(NSDictionary *)options requestToken:(NSDictionary *)requestToken {
    if ((self = [super initWithOptions:options requestToken:requestToken])) {
        self.title = @"MailChimp";
    }
    return self;
}

- (NSURLRequest *)initialRequest {
    NSDictionary *parameters = @{
        @"client_id" : self.options[@"client_id"],
        @"redirect_uri" : self.options[SimpleAuthRedirectURIKey],
        @"response_type" : @"code"
    };
    NSString *URLString = [NSString stringWithFormat:@"%@?%@",
                           MAIL_CHIMP_AUTHORIZE_URI,
                           [CMDQueryStringSerialization queryStringWithDictionary:parameters]];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    return [NSURLRequest requestWithURL:URL];
}

@end
