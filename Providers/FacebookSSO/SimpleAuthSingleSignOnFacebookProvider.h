//
//  SimpleAuthSingleSignOnFacebookProvider.h
//  SimpleAuth
//
//  Created by Julien Seren-Rosso on 10/02/2014.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthProvider.h"
#import "SimpleAuthSingleSignOnProvider.h"

// Facebook
#import <FacebookSDK/FacebookSDK.h>

extern NSString *const SimpleAuthSingleSignOnFacebookProviderDomain;

enum {
    SimpleAuthSingleSignOnFacebookProviderLoginFailed = 1,
    SimpleAuthSingleSignOnFacebookProviderFacebookError
};

@interface SimpleAuthSingleSignOnFacebookProvider : SimpleAuthProvider <SimpleAuthSingleSignOnProvider>

@end
