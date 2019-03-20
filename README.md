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
  - [signInWithBrowser](#signInWithBrowser)
  - [signOutOfOkta](#signoutofokta)
  - [isAuthenticated](#isauthenticated)
  - [authStateManager](#authStateManager)
    - [introspect](#introspect)
    - [renew](#renew)
    - [revoke](#revoke)
    - [getUser](#getuser)
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

**Important**: This is needed if you want to support iOS 10 and older. Starting from iOS 11 Okta uses modern API which does not implies redirects to/from browser.

In order to redirect back to your application from a web browser, you must specify a unique URI to your app. To do this, open `Info.plist` in your application bundle and set a **URL Scheme** to the scheme of the redirect URI.

For example, if your **Redirect URI** is `com.okta.example:/callback`, the **URL Scheme** will be `com.okta.example`.

Next, update your `AppDelegate` to include the following function to allow the redirect to occur:

```swift
// AppDelegate.swift
import OktaAuth

func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
  // oktaAuth - Configured OktaAppAuth instance used to start SignIn/SignOut flow. 
  return oktaAuth.resume(url: url, options: options)
}
```

## Usage Guide

To start using our SDK you have to create a new object of  `OktaAppAuth`. You can instantiate  `OktaAppAuth` w/o parameters that means that SDK will use `Okta.plist` for configuration values. Alternatively you can create `OktaAppAuth` with custom configuration. For details about ways to configure `OktaAppAuth` see the [Configuration Reference](#configuration-reference)

```swift
import OktaAuth

// OktaAppAuth object with default configuration
let defaultOktaAuth = OktaAppAuth()

// OktaAppAuth object with custom configuration 
let customConfig = OktaAuthConfig(...)
let customOktaAuth = OktaAppAuth(configuration: customConfig)

```

You can also browse the full [API reference documentation](#api-reference).

## Configuration Reference

Before using this SDK, you'll need to configure it. Simply create an `OktaAuthConfig` object using one of the methods below.

**Need a refresh token?**
A refresh token is a special token that is used to generate additional access and ID tokens. Make sure to include the `offline_access` scope in your configuration to silently renew the user's session in your application!

### Property list

The easiest way is to create a property list in your application's bundle. By default, this library checks for the existence of the file `Okta.plist`. However any property list file can be used to create configuration object. Ensure one is created with the following fields:

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

Alternatively, you can create a configuration object ( `OktaAuthConfig`) from dictionary with the required values:

```swift
let configuration = OktaAuthConfig(with: [
  "issuer": "https://{yourOktaDomain}/oauth2/default",
  "clientId": "{clientID}",
  "redirectUri": "{redirectUri}",
  "logoutRedirectUri": "{logoutRedirectUri}",
  "scopes": "openid profile offline_access",
  // Custom parameters
  "login_hint": "username@email.com"
])
```

## API Reference

### signInWithBrowser

Start the authorization flow by simply calling `signIn`. 

```swift
oktaAuth.signInWithBrowser(from: self) { tokens, error in
  if let error = error {
    // Error
    return
  }

  // tokens.accessToken
  // tokens.idToken
  // tokens.refreshToken
}
```

### signOutOfOkta

You can start the sign out flow by simply calling `signOutFromOkta`. This method will end the user's Okta session in the browser.

**Important**: This method **does not** clear or revoke tokens minted by Okta. Use the [`revoke`](#revoke) and [`clear`](#clear) methods to terminate the user's local session in your application.

```swift
// Redirects to the configured 'logoutRedirectUri' specified in Okta.plist.
oktaAuth.signOutOfOkta(from: self) { error in
  if let error = error {
    // Error
    return
  }
}
```

### authenticate

If you already logged in to Okta and have a valid session token, you can complete authorization by calling `authenticate(withSessionToken:)`.

```swift
oktaAuth.authenticate(withSessionToken: token) { tokens, error in
  self.hideProgress()
  if let error = error {
    // Error
    return
  }

  // tokens.accessToken
  // tokens.idToken
  // tokens.refreshToken
}
```

### isAuthenticated

Returns `true` if there is a valid access token stored in the TokenManager. This is the best way to determine if a user has successfully authenticated into your app.

```swift
if !oktaAuth.isAuthenticated {
  // Prompt for sign in
}
```

### authStateManager

Tokens are securely stored in the Keychain and can be retrieved by accessing the OktaAuthStateManager. You can request them at any time by calling on the `authStateManager` object bound to `oktaAuth`:

```swift
oktaAuth.authStateManager?.accessToken
oktaAuth.authStateManager?.idToken
oktaAuth.authStateManager?.refreshToken
```

**Note:** Token manager stores tokens of the last logged in user. If you need to use OktaAuth SDK to support several clients you should manage OktaAuthStateManager-s returned by `signIn` operation.

#### introspect

Calls the introspection endpoint to inspect the validity of the specified token.

```swift
oktaAuth.authStateManager?.introspect(token: accessToken, callback: { payload, error in
  guard let isValid = payload["active"] as? Bool else {
    // Error
    return
  }

  print("Is token valid? \(isValid)")
})
```

#### renew

Since access tokens are traditionally short-lived, you can renew expired tokens by exchanging a refresh token for new ones. See the [configuration reference](#configuration-reference) to ensure your app is configured properly for this flow.

```swift
oktaAuth.authStateManager?.renew { newAccessToken, error in
  if let error = error else {
    // Error
    return
  }

  // renewed TokenManager
}
```

#### revoke

Calls the revocation endpoint to revoke the specified token.

```swift
oktaAuth.authStateManager?.revoke(accessToken) { response, error in
  if let error = error else {
    // Error
    return
  }

  // Token was revoked
}
```

#### getUser

Calls the OpenID Connect UserInfo endpoint with the stored access token to return user claim information.

```swift
oktaAuth.authStateManager?.getUser { response, error in
  if let error = error {
    // Error
    return
  }

  // JSON response
}
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
