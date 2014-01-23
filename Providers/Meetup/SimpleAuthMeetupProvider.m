//
//  SimpleAuthMeetupProvider.m
//  SimpleAuth
//
//  Created by Mouhcine El Amine on 17/01/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthMeetupProvider.h"
#import "SimpleAuthMeetupLoginViewController.h"

#import "UIViewController+SimpleAuthAdditions.h"

@implementation SimpleAuthMeetupProvider

#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"meetup";
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
    return options;
}

- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        SimpleAuthMeetupLoginViewController *loginViewController = [[SimpleAuthMeetupLoginViewController alloc] initWithOptions:self.options];
        loginViewController.completion = ^(UIViewController *viewController, NSURL *URL, NSError *error) {
            SimpleAuthInterfaceHandler dismissBlock = self.options[SimpleAuthDismissInterfaceBlockKey];
            dismissBlock(viewController);
            
            NSString *fragment = [URL fragment];
            NSDictionary *dictionary = [CMDQueryStringSerialization dictionaryWithQueryString:fragment];
            NSString *token = dictionary[@"access_token"];
            if ([token length] > 0) {
                NSDictionary *credentials = @{@"token": token,
                                              @"type" : @"bearer",
                                              @"expireDate" : [NSDate dateWithTimeIntervalSinceNow:[dictionary[@"expires_in"] doubleValue]]};
                [self userWithCredentials:credentials
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

- (void)userWithCredentials:(NSDictionary *)credentials completion:(SimpleAuthRequestHandler)completion {
    NSDictionary *parameters = @{ @"member_id" : @"self" };
    NSString *query = [CMDQueryStringSerialization queryStringWithDictionary:parameters];
    NSString *URLString = [NSString stringWithFormat:@"https://api.meetup.com/2/members?%@", query];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", credentials[@"token"]] forHTTPHeaderField:@"Authorization"];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:self.operationQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 99)];
                               NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
                               if ([indexSet containsIndex:statusCode] && data) {
                                   NSError *parseError;
                                   NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data
                                                                                                      options:kNilOptions
                                                                                                        error:&parseError];
                                   if (responseDictionary) {
                                       NSDictionary *rawInfo = [responseDictionary[@"results"] firstObject];
                                       completion ([self dictionaryWithAccount:rawInfo credentials:credentials], nil);
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
    dictionary[@"provider"] = [[self class] type];
    dictionary[@"credentials"] = [NSDictionary dictionaryWithDictionary:credentials];
    dictionary[@"uid"] = account[@"id"];
    dictionary[@"raw_info"] = account;
    NSMutableDictionary *user = [NSMutableDictionary dictionary];
    user[@"name"] = account[@"name"];
    NSDictionary *photoDictionary = account[@"photo"];
    if (photoDictionary) {
        user[@"image"] = photoDictionary[@"photo_link"];
    }
    return dictionary;
}

@end
