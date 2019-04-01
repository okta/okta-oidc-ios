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

import UIKit

public class OktaAppAuth {

    // Current version of the SDK
    static let VERSION = "2.1.0"

    // Cache Okta.plist for reference
    public let configuration: OktaAuthConfig
    
    // Holds the browser session
    private var currentUserSessionTask: UserSessionTask?
    
    public init(configuration: OktaAuthConfig? = nil) throws {
        guard let config = configuration ?? (try? OktaAuthConfig.default()) else {
            throw OktaError.notConfigured
        }
        
        self.configuration = config
    }

    public func signInWithBrowser(from presenter: UIViewController, callback: @escaping ((OktaAuthStateManager?, OktaError?) -> Void)) {
        let signInTask = SignInTask(presenter: presenter, config: configuration, oktaAPI: OktaRestApi())
        currentUserSessionTask = signInTask

        signInTask.run { [weak self] authState, error in
            defer { self?.currentUserSessionTask = nil }
        
            guard let authState = authState else {
                callback(nil, error)
                return
            }
            
            let authStateManager = OktaAuthStateManager(authState: authState)
            callback(authStateManager, nil)
        }
    }

    public func signOutOfOkta(_ authStateManager: OktaAuthStateManager,
                              from presenter: UIViewController,
                              callback: @escaping ((OktaError?) -> Void)) {
        // Use idToken from last auth response since authStateManager.idToken returns idToken only if it is valid.
        // Validation is not needed for SignOut operation.
        guard let idToken = authStateManager.authState.lastTokenResponse?.idToken else {
            callback(OktaError.missingIdToken)
            return
        }
        
        let signOutTask = SignOutTask(idToken: idToken, presenter: presenter, config: configuration, oktaAPI: OktaRestApi())
        currentUserSessionTask = signOutTask
        
        signOutTask.run { [weak self] _, error in
            self?.currentUserSessionTask = nil
            callback(error)
        }
    }

    public func authenticate(withSessionToken sessionToken: String, callback: @escaping ((OktaAuthStateManager?, OktaError?) -> Void)) {
        AuthenticateTask(sessionToken: sessionToken, config: configuration, oktaAPI: OktaRestApi())
        .run { authState, error in
            guard let authState = authState else {
                callback(nil, error)
                return
            }
            
            let authStateManager = OktaAuthStateManager(authState: authState)
            callback(authStateManager, nil)
        }
    }

    @available(iOS, obsoleted: 11.0, message: "Unused on iOS 11+")
    public func resume(_ url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        guard let currentUserSessionTask = currentUserSessionTask else {
            return false
        }
        
        return currentUserSessionTask.resume(with: url)
    }
}
