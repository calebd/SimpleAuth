//
//  SimpleAuthGoogleWebProvider.m
//  SimpleAuth
//
//  Created by Ramon Vicente on 2/24/15.
//  Copyright (c) 2015 UMOBI. All rights reserved.
//

#import "SimpleAuthGoogleWebProvider.h"
#import "SimpleAuthGoogleWebLoginViewController.h"

#import "UIViewController+SimpleAuthAdditions.h"

@implementation SimpleAuthGoogleWebProvider

#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"google-web";
}

+ (NSDictionary *)defaultOptions {
    
    // Default present block
    SimpleAuthInterfaceHandler presentBlock = ^(UIViewController *controller) {
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        UIViewController *presentedViewController = [UIViewController SimpleAuth_presentedViewController];
        [presentedViewController presentViewController:navigationController
                                              animated:YES
                                            completion:nil];
    };
    
    // Default dismiss block
    SimpleAuthInterfaceHandler dismissBlock = ^(id viewController) {
        [viewController dismissViewControllerAnimated:YES
                                           completion:nil];
    };
    
    NSMutableDictionary *options = [NSMutableDictionary dictionaryWithDictionary:[super defaultOptions]];
    options[SimpleAuthPresentInterfaceBlockKey] = presentBlock;
    options[SimpleAuthDismissInterfaceBlockKey] = dismissBlock;
    options[SimpleAuthRedirectURIKey] = @"http://localhost";
    options[@"scope"] = @"email openid profile";
    return options;
}

- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        SimpleAuthGoogleWebLoginViewController *loginViewController = [[SimpleAuthGoogleWebLoginViewController alloc] initWithOptions:self.options];
        loginViewController.completion = ^(UIViewController *viewController, NSURL *URL, NSError *error) {
            SimpleAuthInterfaceHandler dismissBlock = self.options[SimpleAuthDismissInterfaceBlockKey];
            dismissBlock(viewController);
            
            NSString *query = [URL query];
            NSDictionary *dictionary = [CMDQueryStringSerialization dictionaryWithQueryString:query];
            NSString *code = dictionary[@"code"];
            if ([code length] > 0) {
                [self userWithCode:code
                               completion:completion];
            } else {
                completion(nil, error);
            }
        };
        SimpleAuthInterfaceHandler block = self.options[SimpleAuthPresentInterfaceBlockKey];
        block(loginViewController);
    });
}

#pragma mark - Private
- (void)userWithCode:(NSString *)code completion:(SimpleAuthRequestHandler)completion
{
    NSDictionary *parameters = @{ @"code" : code,
                                  @"client_id" : self.options[@"client_id"],
                                  @"client_secret" : self.options[@"client_secret"],
                                  @"redirect_uri": self.options[@"redirect_uri"],
                                  @"grant_type": @"authorization_code"};
    
    NSString *data = [CMDQueryStringSerialization queryStringWithDictionary:parameters];
    
    NSString *URLString = [NSString stringWithFormat:@"https://accounts.google.com/o/oauth2/token"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[data dataUsingEncoding:NSUTF8StringEncoding]];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:self.operationQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 99)];
                               NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
                               if ([indexSet containsIndex:statusCode] && data) {
                                   NSError *parseError;
                                   NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                                                      options:kNilOptions
                                                                                                        error:&parseError];
                                   NSString *token = dictionary[@"access_token"];
                                   if ([token length] > 0) {
                                       
                                       NSDictionary *credentials = @{
                                                                     @"access_token" : token,
                                                                     @"expires" : [NSDate dateWithTimeIntervalSinceNow:[dictionary[@"expires_in"] doubleValue]],
                                                                     @"token_type" : @"bearer",
                                                                     @"id_token": dictionary[@"id_token"]
                                                                     };
                                       
                                       [self userWithCredentials:credentials
                                                      completion:completion];
                                   } else {
                                       completion(nil, parseError);
                                   }
                                   
                               } else {
                                   completion(nil, connectionError);
                               }
    }];
}

- (void)userWithCredentials:(NSDictionary *)credentials completion:(SimpleAuthRequestHandler)completion {
    
    NSString *URLString = [NSString stringWithFormat:@"https://www.googleapis.com/userinfo/v2/me"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    
    [request setValue:[NSString stringWithFormat:@"Bearer %@", credentials[@"access_token"]] forHTTPHeaderField:@"Authorization"];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:self.operationQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 99)];
                               NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
                               if ([indexSet containsIndex:statusCode] && data) {
                                   NSError *parseError;
                                   NSDictionary *userInfo = [NSJSONSerialization JSONObjectWithData:data
                                                                                                      options:kNilOptions
                                                                                                        error:&parseError];
                                   if (userInfo) {
                                       completion ([self dictionaryWithAccount:userInfo credentials:credentials], nil);
                                   } else {
                                       completion(nil, parseError);
                                   }
                               } else {
                                   completion(nil, connectionError);
                               }
                           }];
}

- (NSDictionary *)dictionaryWithAccount:(NSDictionary *)account
                            credentials:(NSDictionary *)credentials
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    // Provider
    dictionary[@"provider"] = [[self class] type];
    
    // Credentials
    dictionary[@"credentials"] = @{
                                   @"token" : credentials[@"access_token"],
                                   @"expires_at" : credentials[@"expires"]
                                   };
    
    // User ID
    dictionary[@"uid"] = account[@"id"];
    
    // Raw response
    dictionary[@"extra"] = @{
                             @"raw_info" : account
                             };
    
    // Location
    NSString *location = account[@"location"][@"name"];
    
    // User info
    NSMutableDictionary *user = [NSMutableDictionary new];
    if (account[@"email"]) {
        user[@"email"] = account[@"email"];
    }
    user[@"name"] = account[@"name"];
    user[@"first_name"] = account[@"given_name"];
    user[@"last_name"] = account[@"family_name"];
    user[@"gender"] = account[@"gender"];
    
    user[@"image"] = account[@"picture"];
    if (location) {
        user[@"location"] = location;
    }
    user[@"verified"] = account[@"verified_email"] ? @YES : @NO;
    user[@"urls"] = @{
                      @"Google +" : account[@"link"],
                      };
    
    dictionary[@"info"] = user;
    
    return dictionary;
}

@end
