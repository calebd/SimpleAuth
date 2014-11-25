//
//  SimpleAuthProvider.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 11/6/13.
//  Copyright (c) 2013-2014 Byliner, Inc. All rights reserved.
//

#import "SimpleAuthProvider.h"
#import "UIViewController+SimpleAuthAdditions.h"
#import "UIWindow+SimpleAuthAdditions.h"

@implementation SimpleAuthProvider

#pragma mark - Public

+ (NSString *)type {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

+ (NSDictionary *)defaultOptions {
    return @{};
}

- (instancetype)initWithOptions:(NSDictionary *)options {
    if ((self = [super init])) {
        _options = [options copy];
        _operationQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion {
    [self doesNotRecognizeSelector:_cmd];
}

- (void)presentLoginViewController:(UIViewController *)controller {
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:controller];
    navigation.modalPresentationStyle = UIModalPresentationFormSheet;
    UIViewController *presented = [UIViewController SimpleAuth_presentedViewController];
    [presented presentViewController:navigation animated:YES completion:nil];
}

- (void)presentActionSheet:(UIActionSheet *)actionSheet {
    UIWindow *window = [UIWindow SimpleAuth_mainWindow];
    [actionSheet showInView:window];
}

- (void)presentAlertController:(UIAlertController *)alertController {
    UIViewController *presented = [UIViewController SimpleAuth_presentedViewController];
    
    UIWindow *window = [UIWindow SimpleAuth_mainWindow];

    if (alertController.popoverPresentationController) {
        // Remove arrow from action sheet.
        [alertController.popoverPresentationController setPermittedArrowDirections:0];
        
        //For set action sheet to middle of view.
        CGRect rect = window.frame;
        rect.origin.x = window.frame.size.width / 20;
        rect.origin.y = window.frame.size.height / 20;
        alertController.popoverPresentationController.sourceView = window;
        alertController.popoverPresentationController.sourceRect = rect;
    }
    
    
    [presented presentViewController:alertController animated:YES completion:nil];
}


@end
