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

import Foundation
import AppKit

public extension OktaOidc {

    @objc func signInWithBrowser(redirectServerConfiguration: OktaRedirectServerConfiguration? = nil,
                                 callback: @escaping ((OktaOidcStateManager?, Error?) -> Void)) {
        let signInTask = OktaOidcBrowserTaskMAC(config: configuration,
                                                oktaAPI: OktaOidcRestApi(),
                                                redirectServerConfiguration: redirectServerConfiguration)
        currentUserSessionTask = signInTask

        signInTask.signIn { [weak self] authState, error in
            defer { self?.currentUserSessionTask = nil }
            NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            self?.handleSignInRedirect(authState: authState, error: error, callback: callback)
        }
    }

    @objc func signOutOfOkta(authStateManager: OktaOidcStateManager,
                             redirectServerConfiguration: OktaRedirectServerConfiguration? = nil,
                             callback: @escaping ((Error?) -> Void)) {
        // Use idToken from last auth response since authStateManager.idToken returns idToken only if it is valid.
        // Validation is not needed for SignOut operation.
        guard let idToken = authStateManager.authState.lastTokenResponse?.idToken else {
            callback(OktaOidcError.missingIdToken)
            return
        }
        let signOutTask = OktaOidcBrowserTaskMAC(config: configuration,
                                                 oktaAPI: OktaOidcRestApi(),
                                                 redirectServerConfiguration: redirectServerConfiguration)
        currentUserSessionTask = signOutTask
        
        signOutTask.signOutWithIdToken(idToken: idToken) { [weak self] _, error in
            defer { self?.currentUserSessionTask = nil }
            NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            callback(error)
        }
    }

    func signOut(authStateManager: OktaOidcStateManager,
                 redirectServerConfiguration: OktaRedirectServerConfiguration? = nil,
                 progressHandler: @escaping ((OktaSignOutOptions) -> Void),
                 completionHandler: @escaping ((Bool, OktaSignOutOptions) -> Void)) {
        self.signOut(with: .allOptions,
                     authStateManager: authStateManager,
                     progressHandler: progressHandler,
                     completionHandler: completionHandler)
    }

    func signOut(with options: OktaSignOutOptions,
                 authStateManager: OktaOidcStateManager,
                 redirectServerConfiguration: OktaRedirectServerConfiguration? = nil,
                 progressHandler: @escaping ((OktaSignOutOptions) -> Void),
                 completionHandler: @escaping ((Bool, OktaSignOutOptions) -> Void)) {
        let  signOutHandler: OktaOidcSignOutHandlerMAC = OktaOidcSignOutHandlerMAC(options: options,
                                                                                   oidcClient: self,
                                                                                   authStateManager: authStateManager)
        signOutHandler.signOut(with: options,
                               failedOptions: [],
                               progressHandler: progressHandler,
                               completionHandler: completionHandler)
    }

    @objc func cancelBrowserSession(completion: (()-> Void)? = nil) {
        guard let userAgentSession = currentUserSessionTask?.userAgentSession else {
            completion?()
            return
        }
        userAgentSession.cancel(completion: completion)
    }

    func handleSignInRedirect(authState: OIDAuthState?,
                              error: Error?,
                              callback: @escaping ((OktaOidcStateManager?, Error?) -> Void)) {
        guard let authState = authState else {
            callback(nil, error)
            return
        }
        
        let authStateManager = OktaOidcStateManager(authState: authState)
        callback(authStateManager, nil)
    }
}
