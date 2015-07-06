//
//  SimpleAuthVKontakteWebLoginViewController.m
//  SimpleAuth
//
//  Created by Mike Cooper on 7/6/15.

//

#import "SimpleAuthVKontakteWebLoginViewController.h"

@implementation SimpleAuthVKontakteWebLoginViewController

#pragma mark - SimpleAuthWebViewController

- (instancetype)initWithOptions:(NSDictionary *)options requestToken:(NSDictionary *)requestToken {
    if ((self = [super initWithOptions:options requestToken:requestToken])) {
        self.title = @"VKontakte";
    }
    return self;
}

- (NSURLRequest *)initialRequest {
    NSDictionary *parameters = @{
        @"client_id" : self.options[@"app_id"],
        @"redirect_uri" : self.options[SimpleAuthRedirectURIKey],
        @"response_type" : @"token",
        @"scope" : [self.options[@"permissions"] componentsJoinedByString:@","],
        @"display" : @"mobile",
        @"v" : @"5.34"
    };
    
    NSString *URLString = [NSString stringWithFormat:
                           @"https://oauth.vk.com/authorize?%@",
                           [CMDQueryStringSerialization queryStringWithDictionary:parameters]];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    return [NSURLRequest requestWithURL:URL];
}

@end
