//
//  SimpleAuthVKontakteWebProvider.m
//  SimpleAuth
//
//  Created by Mikhail Kupriyanov on 7/7/15.
//

#import "SimpleAuthVKontakteWebProvider.h"
#import "SimpleAuthVKontakteWebLoginViewController.h"

#import "UIViewController+SimpleAuthAdditions.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

static const NSString *kVersion_api = @"5.34";

@implementation SimpleAuthVKontakteWebProvider

#pragma mark - SimpleAuthProvider

+ (NSString *)type {
    return @"vkontakte-web";
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
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[super defaultOptions]];
    dictionary[SimpleAuthPresentInterfaceBlockKey] = presentBlock;
    dictionary[SimpleAuthDismissInterfaceBlockKey] = dismissBlock;
    dictionary[SimpleAuthRedirectURIKey] = @"https://oauth.vk.com/blank.html";
    dictionary[@"permission"] = @[ @"email, offline" ];
    dictionary[@"v"] = [kVersion_api copy];
    return dictionary;
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
            SimpleAuthVKontakteWebLoginViewController *login = [[SimpleAuthVKontakteWebLoginViewController alloc] initWithOptions:self.options];
            login.completion = ^(UIViewController *login, NSURL *URL, NSError *error) {
                SimpleAuthInterfaceHandler dismissBlock = self.options[SimpleAuthDismissInterfaceBlockKey];
                dismissBlock(login);
                
                // Parse URL
                NSString *fragment = [URL fragment];
                NSDictionary *dictionary = [CMDQueryStringSerialization dictionaryWithQueryString:fragment];
                NSString *access_token = dictionary[@"access_token"];
                
                // Check for error
                if (![access_token length]) {
                    [subscriber sendError:error];
                    return;
                }
                
                // Send completion
                [subscriber sendNext:dictionary];
                [subscriber sendCompleted];
            };
            
            SimpleAuthInterfaceHandler block = self.options[SimpleAuthPresentInterfaceBlockKey];
            block(login);
        });
        return nil;
    }];
}


- (RACSignal *)accountWithAccessToken:(NSDictionary *) dictionaryWithAccessToken {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSString *accessToken = dictionaryWithAccessToken[@"access_token"];
        NSString *user_id = dictionaryWithAccessToken[@"user_id"];
        NSString *fields = @"sex, bdate, city, country, photo_50, photo_100, photo_200_orig, photo_200, photo_400_orig, photo_max, photo_max_orig, photo_id, online, online_mobile, domain, has_mobile, contacts, connections, site, education, universities, schools, can_post, can_see_all_posts, can_see_audio, can_write_private_message, status, last_seen, common_count, relation, relatives, counters, screen_name, maiden_name, timezone, occupation,activities, interests, music, movies, tv, books, games, about, quotes, personal, friend_status";
        
        NSDictionary *parameters = @{ @"access_token" : accessToken , @"user_id" : user_id, @"fields" : fields, @"v" : self.options[@"v"] };
        NSString *query = [CMDQueryStringSerialization queryStringWithDictionary:parameters];
        NSString *URLString = [NSString stringWithFormat:@"https://api.vk.com/method/users.get?%@", query];
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

- (NSDictionary *)dictionaryWithAccount:(NSDictionary *)account accessToken:(NSDictionary *)accessToken{
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    NSArray *dataArray = (NSArray *) account[@"response"];
    NSDictionary *data = dataArray.lastObject;
    // Provider
    dictionary[@"provider"] = [[self class] type];
    
    // Credentials
    dictionary[@"credentials"] = @{
                                   @"access_token" : accessToken[@"access_token"],
                                   @"expires_in" : accessToken[@"expires_in"]
                                   };
    
    // User ID
    dictionary[@"user_id"] = accessToken[@"user_id"];;
    
    // Raw response
    dictionary[@"extra"] = @{
                             @"raw_info" : data
                             };
    
    // User info
    NSMutableDictionary *user = [NSMutableDictionary new];
    user[@"first_name"] = data[@"first_name"];
    user[@"last_name"] = data[@"last_name"];
    user[@"photo_max_orig"] = data[@"photo_max_orig"];
    
    dictionary[@"user_info"] = user;
    
    return dictionary;
}
@end
