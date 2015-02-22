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
    if (alertController.popoverPresentationController) {
        alertController.popoverPresentationController.permittedArrowDirections = (UIPopoverArrowDirection)0;
        alertController.popoverPresentationController.sourceView = presented.view;
        alertController.popoverPresentationController.sourceRect = presented.view.bounds;
    }
    [presented presentViewController:alertController animated:YES completion:nil];
}


@end
