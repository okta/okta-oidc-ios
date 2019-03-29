/*
 * Copyright (c) 2017-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

// Current version of the SDK
let VERSION = "2.1.0"

// Holds the browser session
public var currentAuthorizationFlow: OIDExternalUserAgentSession?

// Cache Okta.plist for reference
public var configuration = try? OktaAuthConfig.default()

// Cache the Discovery Metadata
public var discoveredMetadata: [String: Any]?

public var authStateManager = OktaAuthStateManager.readFromSecureStorage() {
    didSet {
        authStateManager?.writeToSecureStorage()
    }
}

public var isAuthenticated: Bool {
    return authStateManager?.accessToken != nil
}

public func signInWithBrowser(from presenter: UIViewController, callback: @escaping ((OktaAuthStateManager?, OktaError?) -> Void)) {
    guard let configuration = configuration else {
        callback(nil, OktaError.notConfigured)
        return
    }
    
    SignInTask(presenter: presenter, config: configuration, oktaAPI: OktaRestApi())
    .run { authState, error in
        guard let authState = authState else {
            callback(nil, error)
            return
        }
        
        let authStateManager = OktaAuthStateManager(authState: authState)
        OktaAuth.authStateManager = authStateManager
        callback(authStateManager, nil)
    }
}

public func signOutOfOkta(from presenter: UIViewController, callback: @escaping ((OktaError?) -> Void)) {
    guard let configuration = configuration else {
        callback(OktaError.notConfigured)
        return
    }

    SignOutTask(presenter: presenter, config: configuration, oktaAPI: OktaRestApi())
    .run { _, error in callback(error) }
}

public func authenticate(withSessionToken sessionToken: String, callback: @escaping ((OktaAuthStateManager?, OktaError?) -> Void)) {
    guard let configuration = configuration else {
        callback(nil, OktaError.notConfigured)
        return
    }

    AuthenticateTask(sessionToken: sessionToken, config: configuration, oktaAPI: OktaRestApi())
    .run { authState, error in
        guard let authState = authState else {
            callback(nil, error)
            return
        }
        
        let authStateManager = OktaAuthStateManager(authState: authState)
        OktaAuth.authStateManager = authStateManager
        callback(authStateManager, nil)
    }
}

public func clear() {
    // Clear auth state
    authStateManager?.clear()
    authStateManager = nil
}

public func resume(_ url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
    if let authorizationFlow = currentAuthorizationFlow, authorizationFlow.resumeExternalUserAgentFlow(with: url){
        currentAuthorizationFlow = nil
        return true
    }
    return false
}
