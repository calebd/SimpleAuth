# SimpeAuth

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

## Challenges

The biggest challenge I face at this point is enabling customization of the authentication process. Almost all of the above providers require presenting UI to the user. Twitter requires an action sheet for selecting an account from all present system accounts and Instagram requires a web view controller. I need a generic mechanism that can allow the caller to change the behavior of presented UI.

## License

SimpleAuth is released under the MIT license.
