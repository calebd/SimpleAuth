//
//  SimpleAuthFeedlyWebProvider.m
//  SimpleAuth
//
//  Created by Luís Portela Afonso on 26/02/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthFeedlyWebProvider.h"
#import "SimpleAuthFeedlyWebLoginViewController.h"

#import "UIViewController+SimpleAuthAdditions.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@implementation SimpleAuthFeedlyWebProvider

+ (NSString *)type
{
	return @"feedly-web";
}

+ (NSDictionary *)defaultOptions
{
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
    return dictionary;
}

- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion
{
	[[[self authenticationCode] flattenMap:^(id response) {
		NSArray *signals = @[
							 [self exchangeCodeForRefreshAndAccess:response],
							 [RACSignal return:response]
							 ];
		return signals[0];
	}]
	subscribeNext:^(id response) {
		completion(response, nil);
	}
	error:^(NSError *error) {
		completion(nil, error);
	}];
}

#pragma mark - Private Methods

- (RACSignal*)authenticationCode
{
	return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		dispatch_async(dispatch_get_main_queue(), ^{
			
			SimpleAuthFeedlyWebLoginViewController *login = [[SimpleAuthFeedlyWebLoginViewController alloc] initWithOptions:self.options];
			
			login.completion = ^(UIViewController *controller, NSURL *URL, NSError *error) {
                SimpleAuthInterfaceHandler block = self.options[SimpleAuthDismissInterfaceBlockKey];
                block(controller);
                
                // Parse URL
				NSDictionary *dictionary = [CMDQueryStringSerialization dictionaryWithQueryString:[URL query]];
				
				id apiError = dictionary[@"error"];
                
				// Check for error
				if (apiError != nil)
				{
					[subscriber sendError:error];
                    return;
                }
				
				NSString *code = dictionary[@"code"];
				NSString *state = dictionary[@"state"];
				
                // Send completion
                [subscriber sendNext:@{@"code": code, @"state": state}];
				[subscriber sendCompleted];
            };
            
            SimpleAuthInterfaceHandler block = self.options[SimpleAuthPresentInterfaceBlockKey];
            block(login);
			
		});
		
		return nil;
	}];
}

- (RACSignal*)exchangeCodeForRefreshAndAccess:(NSDictionary *)codeState
{
	return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
		
		NSDictionary *parameters = @{
									 @"code" : codeState[@"code"],
									 @"client_id" : self.options[@"client_id"],
									 @"client_secret" : self.options[@"client_secret"],
									 @"redirect_uri" : self.options[@"redirect_uri"],
									 @"grant_type" : @"authorization_code",
									 @"state" : (codeState[@"state"] != nil ? codeState[@"state"] : @"state.passed.in")
									 };
		
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://feedly.com/v3/auth/token"]];
		
		[request setHTTPMethod:@"POST"];
		[request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
		[request setHTTPBody:[[CMDQueryStringSerialization queryStringWithDictionary:parameters] dataUsingEncoding:NSUTF8StringEncoding]];
        
		[NSURLConnection sendAsynchronousRequest:request queue:self.operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
			
			if (connectionError != nil)
			{
				[subscriber sendError:connectionError];
			}
			else
			{
			
				NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 99)];
				NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
				if ([indexSet containsIndex:statusCode] && data)
				{
					__weak NSError *parseError = nil;
					__weak NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&parseError];
				
					if (parseError != nil)
					{
						[subscriber sendError:parseError];
					}
					else
					{
						[subscriber sendNext:dictionary];
						[subscriber sendCompleted];
					}
				}
			}
		}];
        
        return nil;
	}];
}

@end
