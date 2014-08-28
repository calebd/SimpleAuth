//
//  SimpleAuthTrelloProvider.m
//  SimpleAuth
//
//  Created by Damiano Buscemi on 22/08/14.
//  Copyright (c) 2014 Crispy Bacon, S.r.l. All rights reserved.
//

#import "SimpleAuthTrelloProvider.h"
#import "SimpleAuthTrelloLoginViewController.h"

#import <ReactiveCocoa/ReactiveCocoa.h>
#import "UIViewController+SimpleAuthAdditions.h"

@implementation SimpleAuthTrelloProvider

#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"trello-web";
}

+ (NSDictionary *)defaultOptions {
    
    // Default present block
    SimpleAuthInterfaceHandler presentBlock = ^(UIViewController *controller) {
        UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:controller];
        navigation.modalPresentationStyle = UIModalPresentationFormSheet;
        UIViewController *presented = [UIViewController SimpleAuth_presentedViewController];
        [presented presentViewController:navigation animated:YES completion:nil];
    };
    
    // Default dismiss block
    SimpleAuthInterfaceHandler dismissBlock = ^(id controller) {
        [controller dismissViewControllerAnimated:YES completion:nil];
    };
    
    NSMutableDictionary *options = [NSMutableDictionary dictionaryWithDictionary:[super defaultOptions]];
    options[SimpleAuthPresentInterfaceBlockKey] = presentBlock;
    options[SimpleAuthDismissInterfaceBlockKey] = dismissBlock;
    options[SimpleAuthRedirectURIKey] = @"simple-auth://trello-web.auth";
    return options;
}


- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion {
    [[[self accessToken]
      flattenMap:^RACStream *(NSString *response) {
          NSArray *signals = @[
                               [self accountWithAccessToken:response],
                               [RACSignal return:response]
                               ];
          return [self rac_liftSelector:@selector(dictionaryWithAccount:accessToken:) withSignalsFromArray:signals];
      }]
     subscribeNext:^(NSDictionary *response) {
         completion(response, nil);
     }
     error:^(NSError *error) {
         completion(nil, error);
     }];
}


#pragma mark - Private

- (RACSignal *)accessToken {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        dispatch_async(dispatch_get_main_queue(), ^{
            SimpleAuthTrelloLoginViewController *login = [[SimpleAuthTrelloLoginViewController alloc] initWithOptions:self.options];
            login.completion = ^(UIViewController *login, NSURL *URL, NSError *error) {
                SimpleAuthInterfaceHandler dismissBlock = self.options[SimpleAuthDismissInterfaceBlockKey];
                dismissBlock(login);
                
                // Parse URL
                NSString *fragment = [URL fragment];
                NSDictionary *dictionary = [CMDQueryStringSerialization dictionaryWithQueryString:fragment];
                NSString *token = dictionary[@"token"];
                
                // Check for error
                if (![token length]) {
                    [subscriber sendError:error];
                    return;
                }
                
                // Send completion
                [subscriber sendNext:token];
                [subscriber sendCompleted];
            };
            
            SimpleAuthInterfaceHandler block = self.options[SimpleAuthPresentInterfaceBlockKey];
            block(login);
        });
        return nil;
    }];
}


- (RACSignal *)accountWithAccessToken:(NSString *)accessToken {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSDictionary *parameters = @{ @"token" : accessToken , @"key" : self.options[@"key"] };
        NSString *query = [CMDQueryStringSerialization queryStringWithDictionary:parameters];
        NSString *URLString = [NSString stringWithFormat:@"https://trello.com/1/members/me?%@", query];
        NSURL *URL = [NSURL URLWithString:URLString];
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        [NSURLConnection sendAsynchronousRequest:request queue:self.operationQueue
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                   NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 99)];
                                   NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
                                   if ([indexSet containsIndex:statusCode] && data) {
                                       NSError *parseError = nil;
                                       NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&parseError];
                                       if (dictionary) {
                                           [subscriber sendNext:dictionary];
                                           [subscriber sendCompleted];
                                       }
                                       else {
                                           [subscriber sendError:parseError];
                                       }
                                   }
                                   else {
                                       [subscriber sendError:connectionError];
                                   }
                               }];
        return nil;
    }];
}


#pragma mark - Private

- (NSDictionary *)dictionaryWithAccount:(NSDictionary *)account accessToken:(NSString *)accessToken {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    NSDictionary *data = account;
    
    // Provider
    dictionary[@"provider"] = [[self class] type];
    
    // Credentials
    dictionary[@"credentials"] = @{
                                   @"token" : accessToken
                                   };
    
    // User ID
    dictionary[@"uid"] = data[@"id"];
    
    // Extra
    dictionary[@"extra"] = @{
                             @"raw_info" : account
                             };
    
    // User info
    NSMutableDictionary *user = [NSMutableDictionary new];
    user[@"name"] = data[@"fullName"];
    user[@"username"] = data[@"username"];
    user[@"avatarHash"] = data[@"avatarHash"];
    dictionary[@"user_info"] = user;
    
    return dictionary;
}

@end
