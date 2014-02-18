//
//  SADProviderListViewController.m
//  SimpleAuth
//
//  Created by Caleb Davenport on 1/16/14.
//  Copyright (c) 2014 Byliner, Inc. All rights reserved.
//

#import "SADProviderListViewController.h"

#import "SimpleAuth.h"

@interface SADProviderListViewController ()

@end

@implementation SADProviderListViewController

#pragma mark - NSObject

- (instancetype)init {
    if ((self = [super initWithStyle:UITableViewStylePlain])) {
        self.title = @"SimpleAuth";
    }
    return self;
}


#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    self.tableView.rowHeight = 50.0;
    self.tableView.separatorInset = UIEdgeInsetsZero;
}


#pragma mark - Private

+ (NSArray *)providers {
    static dispatch_once_t token;
    static NSArray *array;
    dispatch_once(&token, ^{
        array = @[
            @"twitter",
            @"twitter-web",
            @"facebook",
            @"facebook-web",
            @"instagram",
            @"meetup",
            @"tumblr",
			@"foursquare-web",
            @"dropbox-web",
            @"linkedin-web",
			@"sinaweibo-web"
        ];
    });
    return array;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[self class] providers] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.textLabel.text = [[self class] providers][indexPath.row];
    return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *provider = [[self class] providers][indexPath.row];
    NSDictionary *configuration = SimpleAuth.configuration[provider];
    if ([configuration count] == 0) {
        NSLog(@"It looks like you haven't configured the \"%@\" provider.\n"
              "Consider calling +[SimpleAuth configuration] in `application:willFinishLaunchingWithOptions: "
              "and providing all relevant options for the given provider.",
              provider);
        return;
    }
    
    [SimpleAuth authorize:provider completion:^(id responseObject, NSError *error) {
        NSLog(@"\nResponse: %@\nError:%@", responseObject, error);
    }];
}

@end
