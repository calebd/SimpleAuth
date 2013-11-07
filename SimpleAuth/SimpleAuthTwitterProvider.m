//
//  SimpleAuthTwitterProvider.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013 SimpleAuth. All rights reserved.
//

#import "SimpleAuthTwitterProvider.h"
#import "SimpleAuth_Internal.h"

#import <cocoa-oauth/GCOAuth.h>
#import <SAMCategories/NSDictionary+SAMAdditions.h>

@interface SimpleAuthTwitterProvider () <UIActionSheetDelegate>

@end

@implementation SimpleAuthTwitterProvider {
    NSArray *_accounts;
    SimpleAuthSystemAccountHandler _systemAccountCompletion;
}

#pragma mark - NSObject

+ (void)load {
    @autoreleasepool {
        [SimpleAuth registerProviderClass:self];
    }
}


#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"twitter";
}


#pragma mark - SimpleAuthSystemProvider

- (void)authorizeWithSystemAccount:(ACAccount *)account completion:(SimpleAuthRequestHandler)completion {
    [self reverseAuthRequestToken:^(id responseObject, NSHTTPURLResponse *response, NSError *error) {
        if (!responseObject) {
            // Handle error
            return;
        }
        [self accessTokenWithReverseAuthRequestToken:responseObject account:account completion:^(id responseObject, NSHTTPURLResponse *response, NSError *error) {
            if (!responseObject) {
                // Handle error
                return;
            }
            completion(responseObject, response, error);
        }];
    }];
}


- (void)loadSystemAccount:(SimpleAuthSystemAccountHandler)completion {
    ACAccountStore *store = [[self class] accountStore];
    ACAccountType *type = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [store requestAccessToAccountsWithType:type options:nil completion:^(BOOL granted, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                NSArray *accounts = [store accountsWithAccountType:type];
                NSUInteger numberOfAccounts = [accounts count];
                if (numberOfAccounts == 0) {
                    completion(nil, error ?: [[NSError alloc] initWithDomain:ACErrorDomain code:ACErrorAccountNotFound userInfo:nil]);
                }
                else if (numberOfAccounts == 1) {
                    completion([accounts lastObject], nil);
                }
                else {
                    _systemAccountCompletion = completion;
                    _accounts = accounts;
                    
                    UIActionSheet *sheet = [UIActionSheet new];
                    for (ACAccount *account in accounts) {
                        NSString *title = [NSString stringWithFormat:@"@%@", account.username];
                        [sheet addButtonWithTitle:title];
                    }
                    sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
                    sheet.delegate = self;
                    sheet.cancelButtonIndex = [sheet addButtonWithTitle:NSLocalizedString(@"GENERAL_CANCEL", nil)];
                    [sheet showInView:nil];
                }
            }
            else {
                completion(nil, error ?: [[NSError alloc] initWithDomain:ACErrorDomain code:ACErrorPermissionDenied userInfo:nil]);
            }
        });
    }];
}


#pragma mark - Public

- (void)requestTokenWithParameters:(NSDictionary *)parameters completion:(SimpleAuthRequestHandler)completion {
    NSDictionary *configuration = [[self class] configuration];
    
    NSURLRequest *request = [GCOAuth
     URLRequestForPath:@"/oauth/request_token"
     POSTParameters:parameters
     scheme:@"https"
     host:@"api.twitter.com"
     consumerKey:configuration[@"consumer_key"]
     consumerSecret:configuration[@"consumer_secret"]
     accessToken:nil
     tokenSecret:nil];
    
    [NSURLConnection
     sendAsynchronousRequest:request
     queue:[NSOperationQueue mainQueue]
     completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
         NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
         NSInteger statusCode = [HTTPResponse statusCode];
         if (statusCode == 200) {
             NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
             completion(string, HTTPResponse, nil);
         }
         else {
             completion(nil, HTTPResponse, error);
         }
     }];
}


- (void)reverseAuthRequestToken:(SimpleAuthRequestHandler)completion {
    NSDictionary *parameters = @{
        @"x_auth_mode" : @"reverse_auth"
    };
    [self requestTokenWithParameters:parameters completion:completion];
}


- (void)accessTokenWithReverseAuthRequestToken:(NSString *)token account:(ACAccount *)account completion:(SimpleAuthRequestHandler)completion {
    NSDictionary *configuration = [[self class] configuration];
    
    NSURL *URL = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
    NSDictionary *parameters = @{
        @"x_reverse_auth_parameters" : token,
        @"x_reverse_auth_target" : configuration[@"consumer_key"]
    };
    SLRequest *request = [SLRequest
     requestForServiceType:SLServiceTypeTwitter
     requestMethod:SLRequestMethodPOST
     URL:URL
     parameters:parameters];
    request.account = account;
    [request performRequestWithHandler:^(NSData *data, NSHTTPURLResponse *HTTPResponse, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger statusCode = [HTTPResponse statusCode];
            if (statusCode == 200) {
                NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSDictionary *dictionary = [NSDictionary sam_dictionaryWithFormEncodedString:string];
                completion(dictionary, HTTPResponse, nil);
            }
            else {
                completion(nil, HTTPResponse, error);
            }
        });
    }];
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        _systemAccountCompletion(nil, nil);
    }
    else {
        ACAccount *account = _accounts[buttonIndex];
        _systemAccountCompletion(account, nil);
    }
    _systemAccountCompletion = nil;
}

@end
