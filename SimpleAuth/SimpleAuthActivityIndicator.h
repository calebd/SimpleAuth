//
//  SimpleAuthActivityIndicator.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 4/21/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

@class SimpleAuthProvider;

@protocol SimpleAuthActivityIndicator <NSObject>
@required

- (void)showActivityIndicatorForSimpleAuthProvider:(SimpleAuthProvider *)provider;
- (void)hideActivityIndicatorForSimpleAuthProvider:(SimpleAuthProvider *)provider;

@end
