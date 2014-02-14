//
//  SimpleAuthSingleSignOnProvider.h
//  SimpleAuth
//
//  Created by Julien Seren-Rosso on 14/02/2014.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthProvider.h"

@interface SimpleAuthSingleSignOnProvider : SimpleAuthProvider

- (BOOL)handleCallback:(NSURL *)url;

@end
