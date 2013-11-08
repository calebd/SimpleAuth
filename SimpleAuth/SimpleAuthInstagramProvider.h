//
//  SimpleAuthInstagramProvider.h
//  SimpleAuth
//
//  Created by Caleb on 11/7/13.
//  Copyright (c) 2013 SimpleAuth. All rights reserved.
//

#import "SimpleAuthProvider.h"

@interface SimpleAuthInstagramProvider : SimpleAuthProvider

- (void)instagramAccountWithAccessToken:(NSString *)accessToken completion:(SimpleAuthRequestHandler)completion;

@end
