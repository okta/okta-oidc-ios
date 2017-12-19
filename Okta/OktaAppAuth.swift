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

// Current version of the SDK
let VERSION = "0.3.0"

// Holds the browser session
public var currentAuthorizationFlow: OIDAuthorizationFlowSession?

// Cache Okta.plist for reference
public var configuration: [String: Any]?

// Token manager
public var tokens: OktaTokenManager?

public func login(_ username: String, password: String) -> Login {
    // Attempt to authenticate via Resource Owner Password Grant
    return Login(forUsername: username, forPassword: password)
}

public func login() -> Login {
    // Attempt to authenticate via authorization code flow
    return Login()
}

public func introspect() -> Introspect {
    // Check the validity of the tokens
    return Introspect()
}

public func revoke(_ token: String?, callback: @escaping (Bool?, OktaError?) -> Void) {
    // Revokes the given token
    _ = Revoke(token: token) { response, error in callback( response?.count == 0 ? true : false, error) }
}

public func userinfo(_ callback: @escaping ([String:Any]?, OktaError?) -> Void) {
    // Return userinfo
    _ = UserInfo(token: tokens?.accessToken) { response, error in callback(response, error) }
}

public func refresh() {
    // Get new tokens
    tokens?.authState?.setNeedsTokenRefresh()
    
    tokens?.authState?.performAction(freshTokens: { accessToken, idToken, error in
        if error != nil {
            print("Error fetching fresh tokens: \(error!.localizedDescription)")
            return
        }
        tokens?.accessToken = accessToken
    })
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
