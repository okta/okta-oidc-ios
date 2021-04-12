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

#if os(iOS)
import UIKit

extension OktaOidc: OktaOidcBrowserProtocolIOS {

    @objc public func signInWithBrowser(from presenter: UIViewController,
                                        callback: @escaping ((OktaOidcStateManager?, Error?) -> Void)) {
        signInWithBrowser(from: presenter, additionalParameters: [:], callback: callback)
    }
    
    @objc public func signInWithBrowser(from presenter: UIViewController,
                                        additionalParameters: [String: String],
                                        callback: @escaping ((OktaOidcStateManager?, Error?) -> Void)) {
        let config: OktaOidcConfig
        do {
            config = try configuration.configuration(withAdditionalParams: additionalParameters)
        } catch {
            callback(nil, error)
            return
        }
            
        let oktaAPI = OktaOidcRestApi()
        oktaAPI.requestCustomizationDelegate = config.requestCustomizationDelegate
        let signInTask = OktaOidcBrowserTaskIOS(presenter: presenter, config: config, oktaAPI: oktaAPI)
        signInWithBrowserTask(signInTask, callback: callback)
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
        let oktaAPI = OktaOidcRestApi()
        oktaAPI.requestCustomizationDelegate = configuration.requestCustomizationDelegate
        let signOutTask = OktaOidcBrowserTaskIOS(presenter: presenter, config: configuration, oktaAPI: oktaAPI)
        signOutWithBrowserTask(signOutTask, idToken: idToken, callback: callback)
    }
    
    public func signOut(authStateManager: OktaOidcStateManager,
                        from presenter: UIViewController,
                        progressHandler: @escaping ((OktaSignOutOptions) -> Void),
                        completionHandler: @escaping ((Bool, OktaSignOutOptions) -> Void)) {
        self.signOut(with: .allOptions,
                     authStateManager: authStateManager,
                     from: presenter,
                     progressHandler: progressHandler,
                     completionHandler: completionHandler)
    }

    public func signOut(with options: OktaSignOutOptions,
                        authStateManager: OktaOidcStateManager,
                        from presenter: UIViewController,
                        progressHandler: @escaping ((OktaSignOutOptions) -> Void),
                        completionHandler: @escaping ((Bool, OktaSignOutOptions) -> Void)) {
        let signOutHandler = OktaOidcSignOutHandlerIOS(presenter: presenter,
                                                       options: options,
                                                       oidcClient: self,
                                                       authStateManager: authStateManager)
        signOutHandler.signOut(with: options,
                               failedOptions: [],
                               progressHandler: progressHandler,
                               completionHandler: completionHandler)
    }

    @objc public func cancelBrowserSession(completion: (() -> Void)? = nil) {
        guard let userAgentSession = currentUserSessionTask?.userAgentSession else {
            completion?()
            return
        }
        userAgentSession.cancel(completion: completion)
    }
}
#endif
