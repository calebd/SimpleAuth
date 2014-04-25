//
//  SADActivityIndicator.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 4/21/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SADActivityIndicator.h"

#import <SVProgressHUD/SVProgressHUD.h>

@implementation SADActivityIndicator

- (void)showActivityIndicatorForSimpleAuthProvider:(SimpleAuthProvider *)provider {
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
}


- (void)hideActivityIndicatorForSimpleAuthProvider:(SimpleAuthProvider *)provider {
    [SVProgressHUD dismiss];
}

@end
