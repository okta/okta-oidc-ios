[<img src="https://devforum.okta.com/uploads/oktadev/original/1X/bf54a16b5fda189e4ad2706fb57cbb7a1e5b8deb.png" align="right" width="256px"/>](https://devforum.okta.com/)
[![CI Status](http://img.shields.io/travis/okta/okta-sdk-appauth-ios.svg?style=flat)](https://travis-ci.org/okta/okta-sdk-appauth-ios)
[![Version](https://img.shields.io/cocoapods/v/OktaAuth.svg?style=flat)](http://cocoapods.org/pods/OktaAuth)
[![License](https://img.shields.io/cocoapods/l/OktaAuth.svg?style=flat)](http://cocoapods.org/pods/OktaAuth)
[![Platform](https://img.shields.io/cocoapods/p/OktaAuth.svg?style=flat)](http://cocoapods.org/pods/OktaAuth)

# Okta AppAuth-iOS Wrapper Library

This library is a wrapper around the [AppAuth-iOS](https://github.com/openid/AppAuth-iOS)* SDK for communicating with Okta as an OAuth 2.0 + OpenID Connect provider, and follows current best practice for native apps using [Authorization Code Flow + PKCE](https://developer.okta.com/authentication-guide/implementing-authentication/auth-code-pkce).

> *Okta is using a forked version of [AppAuth-iOS](https://github.com/okta/AppAuth-iOS) with logout functionality. See [#259](https://github.com/openid/AppAuth-iOS/pull/259) for more details on this pending addition.

You can learn more on the [Okta + iOS](https://developer.okta.com/code/ios/) page in our documentation.

**Table of Contents**

<!-- TOC depthFrom:2 depthTo:3 -->

- [Getting Started](#getting-started)
  - [Using Cocoapods](#using-cocoapods)
  - [Handle the redirect](#handle-the-redirect)
- [Usage Guide](#usage-guide)
- [Configuration Reference](#configuration-reference)
  - [Property list](#property-list)
  - [Configuration object](#configuration-object)
- [API Reference](#api-reference)
  - [signin](#signin)
  - [signOutOfOkta](#signoutofokta)
  - [isAuthenticated](#isauthenticated)
  - [getUser](#getuser)
  - [introspect](#introspect)
  - [refresh](#refresh)
  - [revoke](#revoke)
  - [tokens](#tokens)
  - [clear](#clear)
- [Development](#development)
  - [Running Tests](#running-tests)

<!-- /TOC -->

## Getting Started

Installing the Okta AppAuth wrapper into your project is simple. The easiest way to include this library into your project is through [CocoaPods](http://cocoapods.org).

You'll also need:

- An Okta account, called an _organization_ (sign up for a free [developer organization](https://developer.okta.com/signup/) if you need one).
- An Okta Application, configured as a Native App. This is done from the Okta Developer Console and you can find instructions [here](https://developer.okta.com/authentication-guide/implementing-authentication/auth-code-pkce). When following the wizard, use the default properties. They are are designed to work with our sample applications.

### Using Cocoapods

Simply add the following line to your `Podfile`:

```ruby
pod 'OktaAuth'
```

Then install it into your project:

```bash
pod install
```

### Handle the redirect

In order to redirect back to your application from a web browser, you must specify a unique URI to your app. To do this, open `Info.plist` in your application bundle and set a **URL Scheme** to the scheme of the redirect URI.

For example, if your **Redirect URI** is `com.okta.example:/callback`, the **URL Scheme** will be `com.okta.example`.

Next, update your `AppDelegate` to include the following function to allow the redirect to occur:

```swift
// AppDelegate.swift
import OktaAuth

func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
    return OktaAuth.resume(url: url, options: options)
}
```

## Usage Guide

For an overview of this library's features and authentication flows, check out [our developer docs](https://developer.okta.com/code/ios).

<!--
TODO: Once the developer site provides code walkthroughs, update this with a bulleted list of possible flows.
-->

You can also browse the full [API reference documentation](#api-reference).

## Configuration Reference

There are multiple ways you can configure this library to perform authentication into your application. You can create a new `plist` file with shared values or directly pass your configuration into the sign in method directly.

**Need a refresh token?**
A refresh token is a special token that is used to generate additional access and ID tokens. Make sure to include the `offline_access` scope in your configuration to silently renew the user's session in your application!

### Property list

The easiest way is to create a proptery list in your application's bundle. By default, this library checks for the existance of the file `Okta.plist`, however any property list file will suffice. Ensure one is created with the following fields:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>issuer</key>
    <string>https://{yourOktaDomain}.com/oauth2/default</string>
    <key>clientId</key>
    <string>{clientId}</string>
    <key>redirectUri</key>
    <string>{redirectUri}</string>
    <key>logoutRedirectUri</key>
    <string>{logoutRedirectUri}</string>
    <key>scopes</key>
    <string>openid profile offline_access</string>
  </dict>
</plist>
```

### Configuration object

Alternatively, you can create a dictionary with the required values:

```swift
let config = [
  "issuer": "https://{yourOktaDomain}/oauth2/default",
  "clientId": "{clientID}",
  "redirectUri": "{redirectUri}",
  "logoutRedirectUri": "{logoutRedirectUri}",
  "scopes": "openid profile offline_access",
  // Custom parameters
  "login_hint": "username@email.com"
]
```

## API Reference

### signin

Start the authorization flow by simply calling `signIn`. By default, this method uses the values specified in the `Okta.plist` file:

```swift
OktaAuth
  .signInWithBrowser()
  .start(view: self)
  .then { tokens in
    // tokens.accessToken
    // tokens.idToken
    // tokens.refreshToken
  }
  .catch { error in
    // Error
  }
```

Alternatively, use a custom `plist` file using the `withPListConfig` argument:

```swift
OktaAuth
  .signInWithBrowser()
  .start(withPListConfig: "CustomPlist", view: self)
  .then { tokens in
    // tokens.accessToken
    // tokens.idToken
    // tokens.refreshToken
  }
  .catch { error in
    // Error
  }
```

Finally, use a dictionary instead of a `plist`:

```swift
let config: [String: String] = [
  // Your configuation
]

OktaAuth
  .signInWithBrowser()
  .start(withDictConfig: config, view: self)
  .then { tokens in
    // tokens.accessToken
    // tokens.idToken
    // tokens.refreshToken
  }
  .catch { error in
    // Error
  }
```

### signOutOfOkta

You can start the sign out flow by simply calling `signOutFromOkta`. This method will end the user's Okta session in the browser.

**Important**: This method **does not** clear or revoke tokens minted by Okta. Use the [`revoke`](#revoke) and [`clear`](#clear) methods to terminate the user's local session in your application.

```swift
// Redirects to the configured 'logoutRedirectUri' specified in Okta.plist.
OktaAuth
  .signOutFromOkta()
  .start(view: self)
  .then {
    // Additional signout logic
  }
  .catch { error in
    // Error
  }
```

Similar to the [`signIn`](#signin) method, `signOutOfOkta` can accept a custom `plist` or dictionary configuration:

```swift
// Use a custom plist file
OktaAuth
  .signOutFromOkta()
  .start(withPListConfig: "CustomPlist", view: self)
  .then {
    // Additional signout logic
  }
  .catch { error in
    // Error
  }

// Use a dictionary object for configuration
let config: [String: String] = [
  // Your configuation
]

OktaAuth
  .signOutFromOkta()
  .start(withDictConfig: config, view: self)
  .then {
    // Additional signout logic
  }
  .catch { error in
    // Error
  }
```

### isAuthenticated

Returns `true` if there is a valid access token stored in the TokenManager. This is the best way to determine if a user has successfully authenticated into your app.

```swift
if !OktaAuth.isAuthenticated() {
  // Prompt for sign in
}
```

### getUser

Calls the OpenID Connect UserInfo endpoint with the stored access token to return user claim information.

```swift
OktaAuth.getUser() { response, error in
  if error != nil {
    print("Error: \(error!)")
  }

  if let userinfo = response {
    // JSON response
  }
}
```

### introspect

Calls the introspection endpoint to inspect the validity of the specified token.

```swift
OktaAuth
  .introspect()
  .validate(token: token)
  .then { isActive in
    print("Is token valid? \(isActive)")
  }
  .catch { error in
    // Error
  }
```

### refresh

Since access tokens are traditionally short-lived, you can refresh expired tokens by exchanging a refresh token for new ones. See the [configuration reference](#configuration-reference) to ensure your app is configured properly for this flow.

```swift
OktaAuth
  .refresh()
  .then { newAccessToken in
    print(newAccessToken)
  }
  .catch { error in
    // Error
  }
```

### revoke

Calls the revocation endpoint to revoke the specified token.

```swift
OktaAuth
  .revoke(token: token) { response, error in
    if error != nil {
      print("Error: \(error!)")
    }
    if let _ = response {
      print("Token was revoked")
    }
}
```

### tokens

Tokens are securely stored in the Keychain and can be retrieved by accessing the TokenManager. You can request them at any time by calling on the `token` object bound to `OktaAuth`:

```swift
OktaAuth.tokens?.accessToken
OktaAuth.tokens?.idToken
OktaAuth.tokens?.refreshToken
```

### clear

Removes the local authentication state by removing cached tokens in the keychain.

```swift
OktaAuth.clear()
```

## Development

### Running Tests

To perform an end-to-end test, update the `Okta.plist` file to match your configuration as specified in the [prerequisites](#prerequisites). Next, export the following environment variables:

```bash
export USERNAME={username}
export PASSWORD={password}
export CLIENT_ID={clientId}
export ISSUER=https://{yourOktaDomain}/oauth2/default
export REDIRECT_URI={redirectUri}
export LOGOUT_REDIRECT_URI={logoutRedirectUri}

# Run E2E end Unit tests
bash ./scripts/build-and-test.sh
```

**Note:** *You may need to update the emulator device to match your Xcode version*
