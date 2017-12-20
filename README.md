# Okta

[![CI Status](http://img.shields.io/travis/okta/okta-sdk-appauth-ios.svg?style=flat)](https://travis-ci.org/okta/okta-sdk-appauth-ios)
[![Version](https://img.shields.io/cocoapods/v/OktaAuth.svg?style=flat)](http://cocoapods.org/pods/OktaAuth)
[![License](https://img.shields.io/cocoapods/l/OktaAuth.svg?style=flat)](http://cocoapods.org/pods/OktaAuth)
[![Platform](https://img.shields.io/cocoapods/p/OktaAuth.svg?style=flat)](http://cocoapods.org/pods/OktaAuth)

## Overview
This library is a **wrapper** around the [AppAuth-iOS](https://github.com/openid/AppAuth-iOS) SDK for communicating with OAuth 2.0 + OpenID Connect providers, and follows current best practice outlined in [RFC 8252 - OAuth 2.0 for Native Apps](https://tools.ietf.org/html/rfc8252).

This library currently supports:
  - [OAuth 2.0 Authorization Code Flow](https://tools.ietf.org/html/rfc6749#section-4.1) using the [PKCE extension](https://tools.ietf.org/html/rfc7636)
  - [Resource Owner Password Grant](https://tools.ietf.org/html/rfc6749#section-1.3.3)

## Example
To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation
Okta is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "OktaAuth"
```

## Getting Started
You can create an Okta developer account at [https://developer.okta.com/](https://developer.okta.com/). 

  1. After login, navigate to `https://{yourOrg}-admin.oktapreview.com/admin/apps/add-app` and select **Create New App**
  1. Choose **Native** as the platform, Sign on method as **OpenID Connect** then select **Create**.
  1. Populate your new OpenID Connect application with values similar to:

| Setting                       | Value                                                                             |
| -------------------- | --------------------------------------------------- |
| Application Name     | Native OpenId Connect App *(must be unique)* |
| Redirect URIs            | com.okta.{yoursubdomain}:/callback|
| Allowed grant types | Authorization Code, Refresh Token *(recommended)* |

4. Click **Finish** to redirect back to the *General Settings* of your application.
5. Copy the **Client ID**, as it will be needed for the client configuration.

**Note:** *As with any Okta application, make sure you assign Users or Groups to the OpenID Connect Client. Otherwise, no one can use it.*

> If using the [Resource Owner Password Grant](https://tools.ietf.org/html/rfc6749#section-1.3.3), make sure to select it in the **Allowed Grant Types** and select **Client authentication**.


### Configuration
Create an `Okta.plist` file in your application's bundle with the following fields:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>issuer</key>
	<string>https://{yourOktaDomain}.com/oauth2/default</string>
	<key>clientId</key>
	<string>{clientIdValue}</string>
	<key>redirectUri</key>
	<string>{redirectUrlValue}</string>
        <key>scopes</key>
	<array>
		<string>offline_access</string>
		<string>openid</string>
		<string>profile</string>
	</array>
</dict>
</plist>
```
**Note**: *To receive a **refresh_token**, you must include the `offline_access` scope.*

### Update the Private-use URI Scheme
In order to redirect back to your application from a web browser, you must specify a unique URI to your app. To do this, open `Info.plist` in your application bundle and set a **URL Scheme** to the scheme of the redirect URI.

For example, if your **Redirect URI** is `com.okta.example:/callback`, the **URL Scheme** will be `com.okta.example`.

### Resource Owner Password
If using the [Resource Owner Password Grant](https://tools.ietf.org/html/rfc6749#section-1.3.3), you must specify the `clientSecret` in `Okta.plist`:

```xml
<key>clientSecret</key>
<string>{clientSecret}</string>
```

**IMPORTANT**: *It is strongly discouraged to store a `clientSecret` on a distributed app. Please refer to [OAuth 2.0 for Native Apps](https://tools.ietf.org/html/draft-ietf-oauth-native-apps-12#section-8.5) for more information.*

## Authorization
First, update your `AppDelegate` to include the following function to allow the redirect to occur:

```swift
// AppDelegate.swift
import OktaAuth

func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
    return OktaAuth.resume(url: url, options: options)
}
```


Then, you can start the authorization flow by simply calling `login`:

```swift
OktaAuth
    .login()
    .start(view: self) { response, error in
        if error != nil { print(error!) }

        // Success
        if let authResponse = response {
            // authResponse.accessToken
            // authResponse.idToken
        }
    }
```

To login using `username` and `password`:
```swift
OktaAuth
    .login(username: "user@example.com", password: "password")
    .start(view: self) { response, error in
        if error != nil { print(error!) }

        // Success
        if let authResponse = response {
            // authResponse.accessToken
            // authResponse.idToken
        }
    }
```

### Get UserInfo
Calls the OIDC userInfo endpoint to return user information.

```swift
OktaAuth
    .userinfo() { response, error in
        if error != nil { print("Error: \(error!)") }

        if let userinfo = response {
            userinfo.forEach { print("\($0): \($1)") }
        }
    }
```

### Introspect the Token
Calls the introspection endpoint to inspect the validity of the specified token.

```swift
OktaAuth
    .introspect()
    .validate(token: token) { response, error in
        if error != nil { print("Error: \(error!)") }

        if let isActive = response { print("Is token valid? \(isActive)") }
    }
```

### Revoke a Token
Calls the revocation endpoint to revoke the specified token.

```swift
OktaAuth
    .revoke(token: token) { response, error in
        if error != nil { print("Error: \(error!)") }

        if let _ = response { print("Token was revoked") }
    }
```

### Refresh a Token
Refreshes the `accessToken` if the `refreshToken` is provided.

```swift
OktaAuth.refresh()
```

### Token Management
Tokens are securely stored in the Keychain. They can be easily be set and retrieved with the helper methods `set` and `get`.

```swift
OktaAuth
    .login()
    .start(self) { response, error in
        if error != nil { print(error!) }

        if let authResponse = response {
            // Store tokens in keychain
            OktaAuth.tokens?.set(value: authResponse.accessToken!, forKey: "accessToken")
            OktaAuth.tokens?.set(value: authResponse.idToken!, forKey: "idToken")
        }
}

// Retrieve the tokens
OktaAuth.tokens?.get(forKey: "accessToken")
OktaAuth.tokens?.get(forKey: "idToken")
```
