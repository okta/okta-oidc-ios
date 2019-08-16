[![iOS_13 ready](https://img.shields.io/badge/iOS%2013-RELEASE--3.5.1-green?style=for-the-badge&logo=apple)](https://github.com/okta/okta-oidc-ios/releases/tag/3.5.1)

[<img src="https://aws1.discourse-cdn.com/standard14/uploads/oktadev/original/1X/0c6402653dfb70edc661d4976a43a46f33e5e919.png" align="right" width="256px"/>](https://devforum.okta.com/)
[![CI Status](http://img.shields.io/travis/okta/okta-oidc-ios.svg?style=flat)](https://travis-ci.org/okta/okta-oidc-ios)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/OktaOidc.svg?style=flat)](http://cocoapods.org/pods/OktaOidc)
[![License](https://img.shields.io/cocoapods/l/OktaOidc.svg?style=flat)](http://cocoapods.org/pods/OktaOidc)
[![Platform](https://img.shields.io/cocoapods/p/OktaOidc.svg?style=flat)](http://cocoapods.org/pods/OktaOidc)
[![Swift](https://img.shields.io/badge/swift-4.2-orange.svg?style=flat)](https://developer.apple.com/swift/)

# Okta Open ID Connect Library

> This is a new version of this SDK, the new pod name is [OktaOidc](https://cocoapods.org/pods/OktaOidc). The old [OktaAuth](https://cocoapods.org/pods/OktaAuth) pod is now deprecated. 

This library is a swift wrapper around the AppAuth-iOS objective-c code for communicating with Okta as an OAuth 2.0 + OpenID Connect provider, and follows current best practice for native apps using [Authorization Code Flow + PKCE](https://developer.okta.com/authentication-guide/implementing-authentication/auth-code-pkce).

You can learn more on the [Okta + iOS](https://developer.okta.com/code/ios/) page in our documentation. You can also download our [sample application](https://github.com/okta/samples-ios/tree/master/browser-sign-in) 

**Table of Contents**

<!-- TOC depthFrom:2 depthTo:3 -->

- [Getting Started](#getting-started)
  - [Using Cocoapods](#using-cocoapods)
  - [Handle the redirect](#handle-the-redirect)
  - [How to use in Objective-C project](#how-to-use-in-objective-c-project)
- [Usage Guide](#usage-guide)
- [Configuration Reference](#configuration-reference)
  - [Property list](#property-list)
  - [Configuration object](#configuration-object)
- [API Reference](#api-reference)
  - [signInWithBrowser](#signInWithBrowser)
  - [signOutOfOkta](#signoutofokta)
  - [stateManager](#stateManager)
    - [introspect](#introspect)
    - [renew](#renew)
    - [revoke](#revoke)
    - [getUser](#getuser)
- [Development](#development)
  - [Running Tests](#running-tests)

<!-- /TOC -->

## Getting Started

Installing the OktaOidc SDK into your project is simple. The easiest way to include this library into your project is through [CocoaPods](http://cocoapods.org).

You'll also need:

- An Okta account, called an _organization_ (sign up for a free [developer organization](https://developer.okta.com/signup/) if you need one).
- An Okta Application, configured as a Native App. This is done from the Okta Developer Console and you can find instructions [here](https://developer.okta.com/authentication-guide/implementing-authentication/auth-code-pkce). When following the wizard, use the default properties. They are designed to work with our sample applications.

### Cocoapods

Simply add the following line to your `Podfile`:

```ruby
pod 'OktaOidc'
```

Then install it into your project:

```bash
pod install
```

### Carthage

To integrate this SDK into your Xcode project using [Carthage](https://github.com/Carthage/Carthage), specify it in your Cartfile:
```ruby
github "okta/okta-oidc-ios"
```

### Handle the redirect

**Important**: This is needed if you want to support iOS 10 and older. Starting from iOS 11 Okta uses SFAuthenticationSession API (replaced with ASWebAuthenticationSession in iOS 12) that handle redirects from browser by its own. Therefore `application(,open:, options:)` won't be called during SignIn/SignOut operations.

In order to redirect back to your application from a web browser, you must specify a unique URI to your app. To do this, open `Info.plist` in your application bundle and set a **URL Scheme** to the scheme of the redirect URI.

For example, if your **Redirect URI** is `com.okta.example:/callback`, the **URL Scheme** will be `com.okta.example`.
**Note:** Don't make redirect uri in format x.x.x.x, for example `com.okta.another.example`. Safari engine will fail to redirect to your application

Next, update your `AppDelegate` to include the following function to allow the redirect to occur:

```swift
// AppDelegate.swift
import OktaOidc

var oktaOidc: OktaOidc?

func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
  // oktaOidc - Configured OktaOidc instance used to start SignIn/SignOut flow. 
  return oktaOidc.resume(url: url, options: options)
}
```

### How to use in Objective-C project

To use this SDK in Objective-C project, you should do the following:
- Add `use_frameworks!` in your Pod file.
- Add project setting `SWIFT_VERSION = 4.2`.  To do this open Build Settings in Xcode, select Edit -> Add Build setting -> Add User-Defined Setting. Specify `SWIFT_VERSION`  and  `4.2` as setting name and value correspondently.
- Include autogenerated header `OktaOidc/OktaOidc-Swift.h` into your source code.

## Usage Guide

For an overview of this library's features and authentication flows, check out [our developer docs](https://developer.okta.com/code/ios).

<!--
TODO: Once the developer site provides code walkthroughs, update this with a bulleted list of possible flows.
-->

You can also browse the full [API reference documentation](#api-reference).

## Configuration Reference

Before using this SDK you have to create a new object of  `OktaOidc`. You can instantiate  `OktaOidc` w/o parameters that means that SDK will use `Okta.plist` for configuration values. Alternatively you can create `OktaOidc` with custom configuration. 

```swift
import OktaOidc

// Use the default Okta.plist configuration
let oktaOidc = OktaOidc()

// Use configuration from another resource
let config = OktaOidcConfig(/* plist */)
let config = OktaOidcConfig(/* dictionary */)

// Instantiate OktaOidc with custom configuration object
let oktaOidc = OktaOidc(configuration: config)
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

Alternatively, you can create a configuration object ( `OktaOidcConfig`) from dictionary with the required values:

```swift
let configuration = OktaOidcConfig(with: [
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

Start the authorization flow by simply calling `signIn`. In case of successful authorization, this operation will return valid `OktaOidcStateManager` in its callback. Clients are responsible for further storage and maintenance of the manager.

```swift
oktaOidc.signInWithBrowser(from: self) { stateManager, error in
  if let error = error {
    // Error
    return
  }

  // stateManager.accessToken
  // stateManager.idToken
  // stateManager.refreshToken
}
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/browser-sign-in/OktaBrowserSignIn/WelcomeViewController.swift#L35-L46)

### signOutOfOkta

You can start the sign out flow by simply calling `signOutFromOkta` with the appropriate `OktaOidcStateManager` . This method will end the user's Okta session in the browser.

**Important**: This method **does not** clear or revoke tokens minted by Okta. Use the [`revoke`](#revoke) and [`clear`](#clear) methods of `OktaOidcStateManager` to terminate the user's local session in your application.

```swift
// Redirects to the configured 'logoutRedirectUri' specified in Okta.plist.
oktaOidc.signOutOfOkta(authStateManager, from: self) { error in
  if let error = error {
    // Error
    return
  }
}
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/browser-sign-in/OktaBrowserSignIn/SignInViewController.swift#L62-L74)

### authenticate

If you already logged in to Okta and have a valid session token, you can complete authorization by calling `authenticate(withSessionToken:)`. In case of successful authorization, this operation will return valid `OktaOidcStateManager` in its callback. Clients are responsible for further storage and maintenance of the manager.

```swift
oktaOidc.authenticate(withSessionToken: token) { stateManager, error in
  self.hideProgress()
  if let error = error {
    // Error
    return
  }

  // stateManager.accessToken
  // stateManager.idToken
  // stateManager.refreshToken
}
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/UserProfile/UserProfileViewController.swift#L39-L50)

### stateManager

Tokens are securely stored in the Keychain and can be retrieved by accessing the OktaOidcStateManager. 

```swift
stateManager?.accessToken
stateManager?.idToken
stateManager?.refreshToken
```

User is responsible for storing OktaAuthStateManager returned by `signInWithBrowser` or `authenticate` operation. To store manager call the `writeToSecureStorage` method:

```swift
oktaOidc.signInWithBrowser(from: self) { stateManager, error in
  stateManager.writeToSecureStorage()
}
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/browser-sign-in/OktaBrowserSignIn/WelcomeViewController.swift#L44)

To retrieve stored manager call `readFromSecureStorage(for: )` and pass here Okta configuration that corresponds to a manager you are interested in.

```swift
guard let stateManager = OktaOidcStateManager.readFromSecureStorage(for: oktaConfig) else {
    // unauthenticated
}

//authenticated 
// stateManager.accessToken
// stateManager.idToken
// stateManager.refreshToken
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/browser-sign-in/OktaBrowserSignIn/AppDelegate.swift#L32)

**Note:** In OktaOidc SDK 3.0 we added support for multiple Oauth 2.0 accounts. So developer can use Okta endpoint, social endpoint and others in one application. Therefore `OktaOidcStateManager` is stored in keychain using composite key constructed based on configuration. For backward compatibility there is a method `readFromSecureStorage()` that tries to read `OktaOidcStateManager` stored on a legacy way, so user could retrieve previously stored `OktaOidcStateManager` after switching to a newer version of SDK. 

#### introspect

Calls the introspection endpoint to inspect the validity of the specified token.

```swift
stateManager?.introspect(token: accessToken, callback: { payload, error in
  guard let isValid = payload["active"] as? Bool else {
    // Error
    return
  }

  print("Is token valid? \(isValid)")
})
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/browser-sign-in/OktaBrowserSignIn/TokensViewController.swift#L38-L47)

#### renew

Since access tokens are traditionally short-lived, you can renew expired tokens by exchanging a refresh token for new ones. See the [configuration reference](#configuration-reference) to ensure your app is configured properly for this flow.

```swift
stateManager?.renew { newAccessToken, error in
  if let error = error else {
    // Error
    return
  }

  // renewed TokenManager
}
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/browser-sign-in/OktaBrowserSignIn/TokensViewController.swift#L51-L59)

#### revoke

Calls the revocation endpoint to revoke the specified token.

```swift
stateManager?.revoke(accessToken) { response, error in
  if let error = error else {
    // Error
    return
  }

  // Token was revoked
}
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/browser-sign-in/OktaBrowserSignIn/TokensViewController.swift#L65-L75)

#### getUser

Calls the OpenID Connect UserInfo endpoint with the stored access token to return user claim information.

```swift
stateManager?.getUser { response, error in
  if let error = error {
    // Error
    return
  }

  // JSON response
}
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/browser-sign-in/OktaBrowserSignIn/SignInViewController.swift#L28-L38)

#### clear

Removes the local authentication state by removing cached tokens in the keychain.
**Note:** SDK deletes all keychain items accessible to an application.

```swift
stateManager.clear()
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/browser-sign-in/OktaBrowserSignIn/SignInViewController.swift#L70)

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
