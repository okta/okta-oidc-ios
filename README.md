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
  - [authStateManager](#authStateManager)
    - [introspect](#introspect)
    - [renew](#renew)
    - [revoke](#revoke)
    - [getUser](#getuser)
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

**Important**: This is needed if you want to support iOS 10 and older. Starting from iOS 11 Okta uses SFAuthenticationSession API (replaced with ASWebAuthenticationSession in iOS 12) that handle redirects from browser by its own. Therefore `application(,open:, options:)` won't be called during SignIn/SignOut operations.

In order to redirect back to your application from a web browser, you must specify a unique URI to your app. To do this, open `Info.plist` in your application bundle and set a **URL Scheme** to the scheme of the redirect URI.

For example, if your **Redirect URI** is `com.okta.example:/callback`, the **URL Scheme** will be `com.okta.example`.

Next, update your `AppDelegate` to include the following function to allow the redirect to occur:

```swift
// AppDelegate.swift
import OktaAuth

var oktaAuth: OktaAppAuth?

func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
  // oktaAuth - Configured OktaAppAuth instance used to start SignIn/SignOut flow. 
  return oktaAuth.resume(url: url, options: options)
}
```

## Usage Guide

For an overview of this library's features and authentication flows, check out [our developer docs](https://developer.okta.com/code/ios).

<!--
TODO: Once the developer site provides code walkthroughs, update this with a bulleted list of possible flows.
-->

You can also browse the full [API reference documentation](#api-reference).

## Configuration Reference

Before using this SDK you have to create a new object of  `OktaAppAuth`. You can instantiate  `OktaAppAuth` w/o parameters that means that SDK will use `Okta.plist` for configuration values. Alternatively you can create `OktaAppAuth` with custom configuration. 

```swift
import OktaAuth

// Use the default Okta.plist configuration
let oktaAppAuth = OktaAppAuth()

// Use configuration from another resource
let config = OktaAuthConfig(/* plist */)
let config = OktaAuthConfig(/* dictionary */)

// Instantiate OktaAuth with custom configuration object
let oktaAuth = OktaAppAuth(configuration: config)

```

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

Start the authorization flow by simply calling `signIn`. In case of successful authorization, this operation will return valid `OktaAuthStateManager` in its callback. Clients are responsible for further storage and maintenance of the manager.

```swift
oktaAuth.signInWithBrowser(from: self) { authStateManager, error in
  if let error = error {
    // Error
    return
  }

  // authStateManager.accessToken
  // authStateManager.idToken
  // authStateManager.refreshToken
}
```

### signOutOfOkta

You can start the sign out flow by simply calling `signOutFromOkta` with the appropriate `OktaAuthStateManager` . This method will end the user's Okta session in the browser.

**Important**: This method **does not** clear or revoke tokens minted by Okta. Use the [`revoke`](#revoke) and [`clear`](#clear) methods of `OktaAuthStateManager` to terminate the user's local session in your application.

```swift
// Redirects to the configured 'logoutRedirectUri' specified in Okta.plist.
oktaAuth.signOutOfOkta(authStateManager, from: self) { error in
  if let error = error {
    // Error
    return
  }
}
```

### authenticate

If you already logged in to Okta and have a valid session token, you can complete authorization by calling `authenticate(withSessionToken:)`. In case of successful authorization, this operation will return valid `OktaAuthStateManager` in its callback. Clients are responsible for further storage and maintenance of the manager.

```swift
oktaAuth.authenticate(withSessionToken: token) { authStateManager, error in
  self.hideProgress()
  if let error = error {
    // Error
    return
  }

  // authStateManager.accessToken
  // authStateManager.idToken
  // authStateManager.refreshToken
}
```

### authStateManager

Tokens are securely stored in the Keychain and can be retrieved by accessing the OktaAuthStateManager. 

```swift
authStateManager?.accessToken
authStateManager?.idToken
authStateManager?.refreshToken
```

User is responsible for storing OktaAuthStateManager returned by `signInWithBrowser` or `authenticate` operation. To store manager call the `writeToSecureStorage` method:

```swift
oktaAuth.signInWithBrowser(from: self) { authStateManager, error in
  authStateManager.writeToSecureStorage()
}
```

To retrieve stored manager call `readFromSecureStorage(for: )` and pass here Okta configuration that corresponds to a manager you are interested in.

```swift
guard let authStateManager = OktaAuthStateManager.readFromSecureStorage(for: oktaConfig) else {
    // unauthenticated
}

//authenticated 
// authStateManager.accessToken
// authStateManager.idToken
// authStateManager.refreshToken

```

**Note:** In OktaAppAuth SDK 3.0 we added support for multiple Oauth 2.0 accounts. So developer can use Okta endpoint, social endpoint and others in one application. Therefore `OktaAuthStateManager` is stored in keychain using composite key constructed based on configuration. For backward compatibility there is a method `readFromSecureStorage()` that tries to read `OktaAuthStateManager` stored on a legacy way, so user could retrieve previously stored `OktaAuthStateManager` after switching to a newer version of SDK. 

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
