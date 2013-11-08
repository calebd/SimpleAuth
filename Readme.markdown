# SimpleAuth

SimpleAuth is designed to do the hard work of social account login on iOS. It is designed with a small set of public APIs backed by a set of "providers" the implement the functionality needed to communicate with a given service.

I plan to ship the following providers at launch:

- Twitter
- Facebook
- Instagram

I also have plans to provide:

- Twitter web
- Twitter xauth
- Facebook web
- Tumblr

The API for creating providers is likewise simple but it is not concrete yet. Every provider will be in its own git repository and CocoaPod so that you can install just the components you need.

Providers will be able to set fallbacks such that attempting to login with Facebook will fallback to Facebook web if no system account is present.

## Usage

Configuring  and using SimpleAuth is easy:

````objc
// Somewhere in your app boot process
[SimpleAuth configuration][@"twitter"] = @{
    @"consumer_key" : @"KEY",
    @"consumer_secret" : @"SECRET"
};
````

````objc
// Run the login process
[SimpleAuth authorize:@"twitter" completion:^(id responseObject, NSHTTPURLResponse *response, NSError *error) {
    NSLog(@"%@", responseObject);
}];
````

## Challenges

The biggest challenge I face at this point is enabling customization of the authentication process. Almost all of the above providers require presenting UI to the user. Twitter requires an action sheet for selecting an account from all present system accounts and Instagram requires a web view controller. I need a generic mechanism that can allow the caller to change the behavior of presented UI.

## License

SimpleAuth is released under the MIT license.

## Thanks

Special thanks to my friend [@soffes](https://twitter.com/soffes) for advising on the SimpleAuth API design.
