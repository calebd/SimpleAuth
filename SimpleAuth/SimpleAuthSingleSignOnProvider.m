//
//  SimpleAuthSingleSignOnProvider.m
//  SimpleAuth
//
//  Created by Julien Seren-Rosso on 14/02/2014.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthSingleSignOnProvider.h"

@implementation SimpleAuthSingleSignOnProvider

- (BOOL)handleCallback:(NSURL *)url
{
    [self doesNotRecognizeSelector:_cmd];
    return NO;
}

@end
