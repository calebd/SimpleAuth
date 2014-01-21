# SimpleAuth

SimpleAuth is designed to do the hard work of social account login on iOS. It has a small set of public APIs backed by a set of "providers" that implement the functionality needed to communicate with various social services. You can read more about it [here](http://blog.calebd.me/introducing-simpleauth).

SimpleAuth currently has the following providers:

- Facebook (system)
- Twitter (system)
- Instagram
- Twitter (web)
- Meetup
- Tumblr

I would like to have:

- Twitter xauth
- Tumblr xauth
- GitHub
- Foursquare
- Dropbox
- App Dot Net
- Facebook (web)

## Installing

Install SimpleAuth with CocoaPods. For example, to use Facebook and Twitter authentication, add

```ruby
pod 'SimpleAuth/Facebook'
pod 'SimpleAuth/Twitter'
```

to your `Podfile`.

## Usage

Configuring  and using SimpleAuth is easy:

````objc
// Somewhere in your app boot process
SimpleAuth.configuration[@"twitter"] = @{
    @"consumer_key" : @"KEY",
    @"consumer_secret" : @"SECRET"
};
````

````objc
// Authorize
- (void)loginWithTwitter {
    [SimpleAuth authorize:@"twitter" completion:^(id responseObject, NSError *error) {
        NSLog(@"%@", responseObject);
    }];
}
````

## Implementing  a Provider

The API for creating providers is pretty simple. Providers should be stored in `Providers/` and have an appropriately named folder and sub spec. All providers are automatically registered with the framework. There are a handful of methods you'll need to implement:

Register your provider with SimpleAuth:

Let SimpleAuth know what type of provider you are registering:

````objc
+ (NSString *)type {
    return @"facebook";
}
````

Optionally, you may return a set of default options for all authorization options to use:

````objc
+ (NSDictionary *)defaultOptions {
    return @{
        @"permissions" : @[ @"email" ]
    };
}
````

Finally, provide a method for handling authorization:

````objc
- (void)authorizeWithCompletion:(SimpleAuthRequestHandler)completion {
	// Use values in self.options to customize behavior
	// Perform authentication
	// Call the completion
}
````

The rest is up to you! I welcome contributions to SimpleAuth, both improvements to the library itself and new providers.

## License

SimpleAuth is released under the MIT license.

## Thanks

Special thanks to my friend [@soffes](https://twitter.com/soffes) for advising on the SimpleAuth API design.
