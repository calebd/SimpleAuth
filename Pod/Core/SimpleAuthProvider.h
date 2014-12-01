//
//  SimpleAuthProvider.h
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013-2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuth.h"

#import <CMDQueryStringSerialization/CMDQueryStringSerialization.h>

@interface SimpleAuthProvider : NSObject

@property (nonatomic, readonly, copy) NSDictionary *options;
@property (nonatomic, readonly) NSOperationQueue *operationQueue;

+ (NSString *)type;
+ (NSDictionary *)defaultOptions;

- (instancetype)initWithOptions:(NSDictionary *)options;

/**
 Subclasses must subclass this and authenticate the user.
 
 @param completion Completion called when authentication either succeeds or
 fails. This can be called on any thread, as the <code>SimpleAuth</code> class
 handles dispatching this completion onto the main queue.
 */
- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion;

- (void)presentLoginViewController:(UIViewController *)controller;
- (void)presentActionSheet:(UIActionSheet *)actionSheet;
- (void)presentAlertController:(UIAlertController *)alertController;

@end
