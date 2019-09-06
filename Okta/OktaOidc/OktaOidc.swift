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

public class OktaOidc: NSObject {

    // Cache Okta.plist for reference
    @objc public let configuration: OktaOidcConfig
    
    // Holds the browser session
    private var currentUserSessionTask: OktaOidcUserSessionTask?
    
    @objc public init(configuration: OktaOidcConfig? = nil) throws {
        if let config = configuration {
            self.configuration = config
        } else {
            self.configuration = try OktaOidcConfig.default()
        }
    }

    @objc public func signInWithBrowser(from presenter: UIViewController,
                                        callback: @escaping ((OktaOidcStateManager?, Error?) -> Void)) {
        let signInTask = OktaOidcSignInTask(presenter: presenter, config: configuration, oktaAPI: OktaOidcRestApi())
        currentUserSessionTask = signInTask

        signInTask.run { [weak self] authState, error in
            defer { self?.currentUserSessionTask = nil }
        
            guard let authState = authState else {
                callback(nil, error)
                return
            }
            
            let authStateManager = OktaOidcStateManager(authState: authState)
            callback(authStateManager, nil)
        }
    }

    @objc public func signOutOfOkta(_ authStateManager: OktaOidcStateManager,
                                    from presenter: UIViewController,
                                    callback: @escaping ((Error?) -> Void)) {
        // Use idToken from last auth response since authStateManager.idToken returns idToken only if it is valid.
        // Validation is not needed for SignOut operation.
        guard let idToken = authStateManager.authState.lastTokenResponse?.idToken else {
            callback(OktaOidcError.missingIdToken)
            return
        }
        
        let signOutTask = OktaOidcSignOutTask(idToken: idToken, presenter: presenter, config: configuration, oktaAPI: OktaOidcRestApi())
        currentUserSessionTask = signOutTask
        
        signOutTask.run { [weak self] _, error in
            self?.currentUserSessionTask = nil
            callback(error)
        }
    }

    public func signOut(with options: OktaSignOutOptions,
                        authStateManager: OktaOidcStateManager,
                        from presenter: UIViewController,
                        callback: @escaping ((Bool, OktaSignOutOptions, Error?) -> Void)) {
        if options.isEmpty {
            callback(true, [], nil)
            return
        }
        
        var notFinishedOptions: OktaSignOutOptions = options
        if options.contains(.revokeAccessToken) {
            authStateManager.revoke(authStateManager.accessToken) { (success, error) in
                if success {
                    notFinishedOptions.remove(.revokeAccessToken)
                    self.signOut(with: notFinishedOptions,
                                 authStateManager: authStateManager,
                                 from: presenter,
                                 callback: callback)
                } else {
                    callback(false, notFinishedOptions, error)
                }
            }
            return
        }
        
        if options.contains(.revokeRefreshToken) {
            authStateManager.revoke(authStateManager.refreshToken) { (success, error) in
                if success {
                    notFinishedOptions.remove(.revokeRefreshToken)
                    self.signOut(with: notFinishedOptions,
                                 authStateManager: authStateManager,
                                 from: presenter,
                                 callback: callback)
                } else {
                    callback(false, notFinishedOptions, error)
                }
            }
            return
        }

        if options.contains(.signOutFromOkta) {
            self.signOutOfOkta(authStateManager, from: presenter) { error in
                if let error = error {
                    callback(false, notFinishedOptions, error)
                } else {
                    notFinishedOptions.remove(.signOutFromOkta)
                    self.signOut(with: notFinishedOptions,
                                 authStateManager: authStateManager,
                                 from: presenter,
                                 callback: callback)
                }
            }
            return
        }

        if options.contains(.removeTokensFromStorage) {
            try? authStateManager.removeFromSecureStorage()
            notFinishedOptions.remove(.removeTokensFromStorage)
            self.signOut(with: notFinishedOptions,
                         authStateManager: authStateManager,
                         from: presenter,
                         callback: callback)
            return
        }
    }

    @objc public func authenticate(withSessionToken sessionToken: String,
                                   callback: @escaping ((OktaOidcStateManager?, Error?) -> Void)) {
        OktaOidcAuthenticateTask(sessionToken: sessionToken, config: configuration, oktaAPI: OktaOidcRestApi())
        .run { authState, error in
            guard let authState = authState else {
                callback(nil, error)
                return
            }
            
            let authStateManager = OktaOidcStateManager(authState: authState)
            callback(authStateManager, nil)
        }
    }

    @available(iOS, obsoleted: 11.0, message: "Unused on iOS 11+")
    @objc public func resume(_ url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        guard let currentUserSessionTask = currentUserSessionTask else {
            return false
        }
        
        return currentUserSessionTask.resume(with: url)
    }
}
