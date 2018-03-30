/*
 * Copyright (c) 2017, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import AppAuth
import Hydra
import Vinculum

// Current version of the SDK
let VERSION = "1.0.0"

// Holds the browser session
public var currentAuthorizationFlow: OIDAuthorizationFlowSession?

// Cache Okta.plist for reference
public var configuration: [String: Any]?

// Cache the Discovery Metadata
public var wellKnown: [String: Any]?

// Token manager
public var tokens: OktaTokenManager?

public func login(_ username: String, password: String) -> Login {
    // Authenticate via Resource Owner Password Grant
    return Login(forUsername: username, forPassword: password)
}

public func login() -> Login {
    // Authenticate via authorization code flow
    return Login()
}

public func isAuthenticated() -> Bool {
    // Restore state
    guard let encodedAuthStateItem = try? Vinculum.get("OktaAuthStateTokenManager"),
        let encodedAuthState = encodedAuthStateItem else {
        return false
    }

    guard let previousState = NSKeyedUnarchiver
        .unarchiveObject(with: encodedAuthState.value) as? OktaTokenManager else { return false }

    tokens = previousState

    if tokens?.accessToken != nil {
        return true
    }
    return false
}

public func introspect() -> Introspect {
    // Check the validity of the tokens
    return Introspect()
}

public func refresh() -> Promise<String> {
    // Refreshes the access token if a refresh token is present
    return Refresh().refresh()
}

public func revoke(_ token: String?, callback: @escaping (Bool?, OktaError?) -> Void) {
    // Revokes the given token
    _ = Revoke(token: token) { response, error in callback( response?.count == 0 ? true : false, error) }
}

public func getUser(_ callback: @escaping ([String:Any]?, OktaError?) -> Void) {
    // Return user information from the /userinfo endpoint
    _ = UserInfo(token: tokens?.accessToken) { response, error in callback(response, error) }
}

public func clear() {
    // Clear auth state
    tokens?.clear()
}

public func resume(_ url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
    if let authorizationFlow = currentAuthorizationFlow, authorizationFlow.resumeAuthorizationFlow(with: url){
        currentAuthorizationFlow = nil
        return true
    }
    return false
}
