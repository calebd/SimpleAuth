//
//  SimpleAuthTumblrLoginViewController.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 1/16/14.
//  Copyright (c) 2014 Seesaw Decisions Corporation. All rights reserved.
//

#import "SimpleAuthWebViewController.h"

@interface SimpleAuthTumblrLoginViewController : SimpleAuthWebViewController

- (instancetype)initWithOptions:(NSDictionary *)options requestToken:(NSDictionary *)requestToken;

@end
