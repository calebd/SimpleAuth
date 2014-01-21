//
//  SimpleAuthMeetupLoginViewController.m
//  SimpleAuth
//
//  Created by Mouhcine El Amine on 17/01/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthMeetupLoginViewController.h"
#import "SimpleAuth.h"

#import <SAMCategories/NSDictionary+SAMAdditions.h>

@implementation SimpleAuthMeetupLoginViewController

#pragma mark - UIViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSDictionary *parameters = @{@"client_id" : self.options[@"client_id"],
                                 @"redirect_uri" : self.options[SimpleAuthRedirectURIKey],
                                 @"response_type" : @"token",
                                 @"scope" : @"ageless"};
    NSString *URLString = [NSString stringWithFormat:@"https://secure.meetup.com/oauth2/authorize?%@", [parameters sam_stringWithFormEncodedComponents]];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:URLString]]];
}

#pragma mark - SimpleAuthWebViewController

- (instancetype)initWithOptions:(NSDictionary *)options {
    self = [super initWithOptions:options];
    if (self) {
        self.title = @"Meetup";
    }
    return self;
}

@end
