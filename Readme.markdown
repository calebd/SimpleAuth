# SimpleAuth

SimpleAuth is designed to do the hard work of social account login on iOS. It has a small set of public APIs backed by a set of "providers" that implement the functionality needed to communicate with various social services.

SimpleAuth currently has the following providers:

- [Twitter](https://github.com/calebd/SimpleAuth/wiki/Twitter)
- [Facebook](https://github.com/calebd/SimpleAuth/wiki/Facebook)
- [Instagram](https://github.com/calebd/SimpleAuth/wiki/Instagram)
- [Tumblr](https://github.com/calebd/SimpleAuth/wiki/Tumblr)
- [Dropbox](https://github.com/calebd/SimpleAuth/wiki/Dropbox)
- [Foursquare](https://github.com/calebd/SimpleAuth/wiki/Foursquare)
- [Meetup](https://github.com/calebd/SimpleAuth/wiki/Meetup)
- [LinkedIn](https://github.com/calebd/SimpleAuth/wiki/LinkedIn)
- [Sina Weibo](https://github.com/calebd/SimpleAuth/wiki/SinaWeibo)
- [Google](https://github.com/calebd/SimpleAuth/wiki/Google)
- [Box](https://github.com/calebd/SimpleAuth/wiki/Box)
- [OneDrive](https://github.com/calebd/SimpleAuth/wiki/OneDrive)

## Installing

Install SimpleAuth with CocoaPods. For example, to use Facebook and Twitter authentication, add

```ruby
pod 'SimpleAuth/Facebook'
pod 'SimpleAuth/Twitter'
```

to your `Podfile`.

## Usage

Configuring  and using SimpleAuth is easy:

````swift
// Somewhere in your app boot process
SimpleAuth.configuration()["twitter"] = [
    "consumer_key": "KEY",
    "consumer_secret": "SECRET"
]
````

````swift
// Authorize
func loginWithTwitter() {
    SimpleAuth.authorize("twitter", completion: { responseObject, error in
        println("Twitter login response: \(responseObject)")
    })
}
````

## Implementing  a Provider

The API for creating providers is pretty simple. Be sure to look at `SimpleAuthProvider` and `SimpleAuthWebLoginViewController`. These classes will help you simplify your authentiction process. Providers should be stored in `Pod/Providers/` and have an appropriately named folder and sub spec. All providers are automatically registered with the framework. There are a handful of methods you'll need to implement:

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

### Contributors

- [kornifex](https://github.com/kornifex): Foursquare provider
- [mouhcine](https://github.com/mouhcine): Meetup provider
- [iamabhiee](https://github.com/iamabhiee): LinkedIn provider
- [aschuch](https://github.com/aschuch): Sina Weibo provider
