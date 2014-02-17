//
//  SimpleAuthSingleSignOnFacebookProvider.m
//  SimpleAuth
//
//  Created by Julien Seren-Rosso on 10/02/2014.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthSingleSignOnFacebookProvider.h"
#import "SimpleAuth.h"

NSString *const SimpleAuthSingleSignOnFacebookProviderDomain = @"io.simpleauth.sso.facebook";

@interface SimpleAuthSingleSignOnFacebookProvider ()

@property (nonatomic, strong) SimpleAuthRequestHandler completion;

@end


@implementation SimpleAuthSingleSignOnFacebookProvider

#pragma mark - SimpleAuthProvider
    
+ (NSString *)type {
    return @"facebook-sso";
}

+ (NSDictionary *)defaultOptions {
    return @{
        @"permissions" : @[ @"basic_info" ]
    };
}
    
    
- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion
{
    self.completion = completion;
    
    [FBSession openActiveSessionWithReadPermissions:self.options[@"permission"] allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
        [self sessionStateChanged:session state:status error:error];
        
        // Immediately close the session (if successfully opened) in order to retrieve a new token next time
        if ([session isOpen]) {
            [FBSession.activeSession closeAndClearTokenInformation];
        }
    }];
}


#pragma mark - Facebook SSO

- (BOOL)handleCallback:(NSURL *)url
{
    return [FBSession.activeSession handleOpenURL:url];
}

- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error
{
    // If the session was opened successfully
    if (!error && state == FBSessionStateOpen) {
        NSLog(@"Session opened");
    
        // Retrieve the information from the sesssion
        self.completion([self dictionaryWithFBSession:session], nil);
        return;
    }
    
    if (state == FBSessionStateClosed) {
        NSLog(@"Session closed");
        // The session was closed, do nothing
        return;
    }
    
    if (state == FBSessionStateClosedLoginFailed) {
        NSLog(@"Login failed");
        
        // Something wrong happened
        NSError *error = [NSError errorWithDomain:SimpleAuthSingleSignOnFacebookProviderDomain
                                             code:SimpleAuthSingleSignOnFacebookProviderLoginFailed
                                         userInfo:@{ NSLocalizedDescriptionKey: @"Something went wrong, try again." }];
        
        self.completion(nil, error);
        return;
    }
    
    // Handle errors
    if (error) {
        NSLog(@"Facebook error");
        NSError *ssoError = [NSError errorWithDomain:SimpleAuthSingleSignOnFacebookProviderDomain
                                                code:SimpleAuthSingleSignOnFacebookProviderFacebookError
                                            userInfo:@{
                                                       NSLocalizedDescriptionKey: @"Something went wrong, try again.",
                                                       NSUnderlyingErrorKey: error
                                                       }];
        
        self.completion(nil, ssoError);
    }
}


- (NSDictionary *)dictionaryWithFBSession:(FBSession *)session
{
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    
    // Provider
    dictionary[@"provider"] = [[self class] type];
    
    // Credentials
    dictionary[@"credentials"] = @{ @"token" : session.accessTokenData.accessToken };

    return dictionary;
}

@end
