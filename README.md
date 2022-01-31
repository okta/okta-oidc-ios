[<img src="https://aws1.discourse-cdn.com/standard14/uploads/oktadev/original/1X/0c6402653dfb70edc661d4976a43a46f33e5e919.png" align="right" width="256px"/>](https://devforum.okta.com/)
[![CI Status](https://github.com/okta/okta-oidc-ios/actions/workflows/okta-oidc.yml/badge.svg)](https://travis-ci.com/okta/okta-oidc-ios)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/OktaOidc.svg?style=flat)](http://cocoapods.org/pods/OktaOidc)
[![License](https://img.shields.io/cocoapods/l/OktaOidc.svg?style=flat)](http://cocoapods.org/pods/OktaOidc)
[![Platforms](https://img.shields.io/badge/platforms-ios%20%7C%20osx-lightgrey)](http://cocoapods.org/pods/OktaOidc)
[![Swift](https://img.shields.io/badge/swift-5.0-orange.svg?style=flat)](https://developer.apple.com/swift/)

# Okta Open ID Connect Library

> This is a new version of this SDK, the new pod name is [OktaOidc](https://cocoapods.org/pods/OktaOidc). The old [OktaAuth](https://cocoapods.org/pods/OktaAuth) pod is now deprecated. 

This library is a Swift wrapper around the [AppAuth-iOS](https://github.com/openid/AppAuth-iOS) Objective-C code for communicating with Okta as an OAuth 2.0 + OpenID Connect provider, and follows current best practice for native apps using [Authorization Code Flow + PKCE](https://developer.okta.com/authentication-guide/implementing-authentication/auth-code-pkce).

You can learn more on the [Okta + iOS](https://developer.okta.com/code/ios/) page in our documentation. You can also download our [sample application](https://github.com/okta/samples-ios/tree/master/browser-sign-in).

**Table of Contents**

<!-- TOC depthFrom:2 depthTo:3 -->

- [Getting Started](#getting-started)
- [Supported Platforms](#supported-platforms)
- [Install](#install)
- [Usage Guide](#usage-guide)
- [Configuration Reference](#configuration-reference)
  - [Create OIDC object](#create-oidc-object)
  - [Property list](#property-list)
  - [Configuration object](#configuration-object)
  - [How to use in Objective-C project](#how-to-use-in-objective-c-project)
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
- [Modify network requests](#modify-network-requests)
- [Migration](#migration)
- [Known issues](#known-issues)
- [Contributing](#contributing)

<!-- /TOC -->

## Getting Started

Installing the OktaOidc SDK into your project is simple. The easiest way to include this library into your project is through [CocoaPods](http://cocoapods.org).

You'll also need:

- An Okta account, called an _organization_ (sign up for a free [developer organization](https://developer.okta.com/signup/) if you need one).
- An Okta Application, configured as a Native App. This is done from the Okta Developer Console and you can find instructions [here](https://developer.okta.com/authentication-guide/implementing-authentication/auth-code-pkce). When following the wizard, use the default properties. They are designed to work with our sample applications.

**Note:** If you would like to use your own in-app user interface instead of the web browser, you can do so by using our [Swift Authentication SDK](https://github.com/okta/okta-auth-swift).

## Supported Platforms

### iOS
Okta OIDC supports iOS 11 and above.

### macOS
Okta OIDC supports macOS (OS X) 10.14 and above. Library supports both custom schemes; a loopback HTTP redirects via a small embedded server.

## Install

### Swift Package Manager

Add the following to the `dependencies` attribute defined in your `Package.swift` file. You can select the version using the `majorVersion` and `minor` parameters. For example:
```
    dependencies: [
        .Package(url: "https://github.com/okta/okta-oidc-ios.git", majorVersion: <majorVersion>, minor: <minor>)
    ]
```

### Cocoapods

Simply add the following line to your `Podfile`:

```ruby
pod 'OktaOidc'
```

Then install it into your project:

```bash
pod install --repo-update
```

### Carthage

To integrate this SDK into your Xcode project using [Carthage](https://github.com/Carthage/Carthage), specify it in your Cartfile:
```ruby
github "okta/okta-oidc-ios"
```

Then install it into your project:

`carthage update --use-xcframeworks`

**Note:** Make sure Carthage version is 0.37.0 or higher. Otherwise, Carthage can fail.

## Usage Guide

For an overview of this library's features and authentication flows, check out [our developer docs](https://developer.okta.com/code/ios).

<!--
TODO: Once the developer site provides code walkthroughs, update this with a bulleted list of possible flows.
-->

You can also browse the full [API reference documentation](#api-reference).

## Configuration Reference

### Create OIDC object

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

Alternatively, you can create a configuration object (`OktaOidcConfig`) from dictionary with the required values:

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

### Disable Single Sign-On for the authentication session

You can disable SSO capabilities by setting `noSSO` flag to `true` for `OktaOidcConfig` instance.

```swift
let configuration = OktaOidcConfig(with: {YourOidcConfiguration})
if #available(iOS 13.0, *) {
    configuration?.noSSO = true
}
```
***Note*** Flag is available on iOS 13 and above versions


### Token Time Validation

Custom token time validation is possible by adopting to `OKTTokenValidator` protocol and then setting `tokenValidator` variable: 

```swift
configuration?.tokenValidator = self
```

By default `OKTDefaultTokenValidator` object is set. 

### How to use in Objective-C project

To use this SDK in Objective-C project, you should do the following:
- Add `use_frameworks!` in your Pod file.
- Add project setting `SWIFT_VERSION = 5.0`.  To do this open Build Settings in Xcode, select Edit -> Add Build setting -> Add User-Defined Setting. Specify `SWIFT_VERSION`  and  `5.0` as setting name and value correspondently.
- Include autogenerated header `OktaOidc/OktaOidc-Swift.h` into your source code.

## API Reference

### signInWithBrowser

Start the authorization flow by simply calling `signInWithBrowser`. In case of successful authorization, this operation will return valid `OktaOidcStateManager` in its callback. Clients are responsible for further storage and maintenance of the manager.

**Note**: IDP can be passed by specifying an argument with the idp parameter.

#### iOS
```swift
oktaOidc.signInWithBrowser(from: viewController, additionalParameters: ["idp": "your_idp_here"]) { stateManager, error in
  if let error = error {
    // Error
    return
  }

  // stateManager.accessToken
  // stateManager.idToken
  // stateManager.refreshToken
}
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/browser-sign-in/OktaBrowserSignIn/WelcomeViewController.swift#L35-L46).

#### macOS
```swift
// Create redirect server configuration and start local HTTP server if you don't want to use custom schemes
let serverConfig = OktaRedirectServerConfiguration.default
serverConfig.port = 63875
oktaOidc.signInWithBrowser(redirectServerConfiguration: serverConfig, additionalParameters: ["idp": "your_idp_here"]) { stateManager, error in
  if let error = error {
    // Error
    return
  }

  // stateManager.accessToken
  // stateManager.idToken
  // stateManager.refreshToken
}
```

### signOutOfOkta

This method ends the user's Okta session in the browser. The method deletes Okta's persistent cookie and disables SSO capabilities.

**Important**: This method **does not** clear or revoke tokens minted by Okta. Use the [`revoke`](#revoke) and [`clear`](#clear) methods of `OktaOidcStateManager` to terminate the user's local session in your application.

#### iOS
```swift
// Redirects to the configured 'logoutRedirectUri' specified in Okta.plist.
oktaOidc.signOutOfOkta(authStateManager, from: viewController) { error in
  if let error = error {
    // Error
    return
  }
}
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/browser-sign-in/OktaBrowserSignIn/SignInViewController.swift#L62-L74).

#### macOS
```swift
// Create redirect server configuration and start local HTTP server if you don't want to use custom schemes
let serverConfig = OktaRedirectServerConfiguration.default
serverConfig.port = 63875
// Redirects to the configured 'logoutRedirectUri' specified in Okta.plist.
oktaOidc.signOutOfOkta(authStateManager: authStateManager, redirectServerConfiguration: serverConfig) { error in
  if let error = error {
    // Error
    return
  }
}
```

### signOut

This method helps to perform a multi-step sign-out flow. The method provides options that you want to perform and the SDK runs the options as a batch.
The available options are:
- `revokeAccessToken` - SDK revokes access token
- `revokeRefreshToken` - SDK revokes refresh token
- `removeTokensFromStorage` - SDK removes tokens from the secure storage
- `signOutFromOkta` - SDK calls [`signOutOfOkta`](#signoutofokta)
- `revokeTokensOptions` - revokes access and refresh tokens
- `allOptions` - revokes tokens, signs out from Okta, and removes tokens from the secure storage

The order of operations performed by the SDK:
1. Revoke the access token, if the option is set. If this step fails step 3 will be omitted.
2. Revoke the refresh token, if the option is set. If this step fails step 3 will be omitted.
3. Remove tokens from the secure storage, if the option is set.
4. Browser sign out, if the option is set.

#### iOS
```swift
let options: OktaSignOutOptions = .revokeTokensOptions
options.insert(.signOutFromOkta)
oktaOidc?.signOut(authStateManager: authStateManager, from: viewController, progressHandler: { currentOption in
    if currentOption.contains(.revokeAccessToken) {
        // update progress
    } else if currentOption.contains(.revokeRefreshToken) {
        // update progress
    } else if currentOption.contains(.signOutFromOkta) {
        // update progress
    }
}, completionHandler: { success, failedOptions in
    if !success {
        // handle error
    }
})
```

#### macOS
```swift
// Create redirect server configuration and start local HTTP server if you don't want to use custom schemes
let serverConfig = OktaRedirectServerConfiguration.default
serverConfig.port = 63875
let options: OktaSignOutOptions = .revokeTokensOptions
options.insert(.signOutFromOkta)
oktaOidc?.signOut(authStateManager: authStateManager,
                  redirectServerConfiguration: serverConfig,
                  progressHandler: { currentOption in
    if currentOption.contains(.revokeAccessToken) {
        // update progress
    } else if currentOption.contains(.revokeRefreshToken) {
        // update progress
    } else if currentOption.contains(.signOutFromOkta) {
        // update progress
    }
}, completionHandler: { success, failedOptions in
    if !success {
        // handle error
    }
})
```

### authenticate

If you already signed in to Okta and have a valid session token, you can complete authorization by calling `authenticate(withSessionToken:)`. Upon successful authorization, this operation returns a valid `OktaOidcStateManager` in the callback. Clients are responsible for further storage and maintenance of the manager.

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
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/UserProfile/UserProfileViewController.swift#L39-L50).

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
Sample app [example](https://github.com/okta/samples-ios/blob/master/browser-sign-in/OktaBrowserSignIn/WelcomeViewController.swift#L44).

To retrieve stored manager call `readFromSecureStorage(for:)` and pass here Okta configuration that corresponds to a manager you are interested in.

```swift
guard let stateManager = OktaOidcStateManager.readFromSecureStorage(for: oktaConfig) else {
    // unauthenticated
}

//authenticated 
// stateManager.accessToken
// stateManager.idToken
// stateManager.refreshToken
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/browser-sign-in/OktaBrowserSignIn/AppDelegate.swift#L32).

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
Sample app [example](https://github.com/okta/samples-ios/blob/master/browser-sign-in/OktaBrowserSignIn/TokensViewController.swift#L38-L47).

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
Sample app [example](https://github.com/okta/samples-ios/blob/master/browser-sign-in/OktaBrowserSignIn/TokensViewController.swift#L51-L59).

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
Sample app [example](https://github.com/okta/samples-ios/blob/master/browser-sign-in/OktaBrowserSignIn/TokensViewController.swift#L65-L75).

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
Sample app [example](https://github.com/okta/samples-ios/blob/master/browser-sign-in/OktaBrowserSignIn/SignInViewController.swift#L28-L38).

#### clear

Removes the local authentication state by removing cached tokens in the keychain.


**Warning:** SDK deletes all keychain items accessible to an application.

```swift
stateManager.clear()
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/browser-sign-in/OktaBrowserSignIn/SignInViewController.swift#L70).

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

**Note:** *You may need to update the emulator device to match your Xcode version.*

## Modify network requests

You can track and modify network requests made by `OktaOidc`. In order to do this, create an object conforming to the `OktaNetworkRequestCustomizationDelegate` protocol and set it to the `requestCustomizationDelegate` property on an `OktaOidcConfig` instance.

```swift
let configuration = OktaOidcConfig(with: {YourOidcConfiguration})
configuration.requestCustomizationDelegate = {YourDelegateInstance}
```

For example, delegate could be implemented as follows:

```swift
extension SomeNSObject: OktaNetworkRequestCustomizationDelegate {

    func customizableURLRequest(_ request: URLRequest?) -> URLRequest? {
        guard var modifiedRequest = request else {
            return nil
        }
        modifiedRequest.setValue("Some value", forHTTPHeaderField: "custom-header-field")
        print("Okta OIDC network request: \(modifiedRequest)")
        return modifiedRequest
    }

    func didReceive(_ response: URLResponse?) {
        guard let response = response else {
            return
        }
        print("Okta OIDC network response: \(response)")
    }
}
```

***Note:*** It is highly recommended to copy all of the existing parameters from the original URLRequest object to modified request without any changes. Altering of this data could lead network request to fail. If `customizableURLRequest(_:)` method returns `nil` default request will be used.

## Migration

### Migrating from 3.10.x to 3.11.x

The SDK `okta-oidc-ios` has a major changes in error handling. Consider these guidelines to update your code.

- `APIError` is renamed as `api`.
- `api` error has the additional parameter `underlyingError`, it's an optional and indicates the origin of the error.
- Introduced a new error `authorization(error:description:)`.
- `authorization` error appears when authorization server fails due to errors during authorization.
- `unexpectedAuthCodeResponse(statusCode:)` has an error code parameter.
- `OktaOidcError` conforms to `CustomNSError` protocol. It means you can convert the error to `NSError` and get `code`, `userInfo`, `domain`, `underlyingErrors`.
- `OktaOidcError` conforms to `Equatable` protocol. The errors can be compared for equality using the operator `==` or inequality using the operator `!=`.

## Known issues

### iOS shows permission dialog(`{App} Wants to Use {Auth Domain} to Sign In`) for Okta Sign Out flows
Known iOS issue where iOS doesn't provide any good ways to terminate active authentication session and delete SSO cookies. The only proper way for now is to use `ASWebAuthenticationSession` class to terminate the session. `ASWebAuthenticationSession` deletes all SSO cookies however shows `Sign In` persmissions dialog 🤯

You can also consider the following workarounds:
- Use `noSSO` option in OIDC configuration object if you don't need SSO capabilites. Also note that this option works only on iOS 13+ versions
- Fork repository and change user-agent implementation(`OIDExternalUserAgentIOS.m`) to use `SFSafariViewController` only. Some pitfalls of this approach described [here](https://github.com/okta/okta-oidc-ios/issues/181).

## Contributing

We welcome contributions to all of our open-source packages. Please, see the [contribution guide](CONTRIBUTING.md) to understand how to structure a contribution.

