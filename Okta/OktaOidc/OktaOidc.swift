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

public class OktaOidc: NSObject {

    // Cache Okta.plist for reference
    @objc public let configuration: OktaOidcConfig

    @objc public init(configuration: OktaOidcConfig? = nil) throws {
        if let config = configuration {
            self.configuration = config
        } else {
            self.configuration = try OktaOidcConfig.default()
        }
    }

    @objc public func authenticate(withSessionToken sessionToken: String,
                                   callback: @escaping ((OktaOidcStateManager?, Error?) -> Void)) {
        OktaOidcAuthenticateTask(config: configuration, oktaAPI: OktaOidcRestApi())
        .authenticateWithSessionToken(sessionToken: sessionToken) { authState, error in
            guard let authState = authState else {
                callback(nil, error)
                return
            }
            
            let authStateManager = OktaOidcStateManager(authState: authState)
            callback(authStateManager, nil)
        }
    }

    @objc public func hasActiveBrowserSession() -> Bool {
        return currentUserSessionTask != nil
    }

    func signInWithBrowserTask(_ task: OktaOidcBrowserTask,
                               callback: @escaping ((OktaOidcStateManager?, Error?) -> Void)) {
        currentUserSessionTask = task

        task.signIn { [weak self] authState, error in
            defer { self?.currentUserSessionTask = nil }
            guard let authState = authState else {
                callback(nil, error)
                return
            }
            
            let authStateManager = OktaOidcStateManager(authState: authState)
            callback(authStateManager, nil)
        }
    }

    func signOutWithBrowserTask(_ task: OktaOidcBrowserTask,
                                idToken: String,
                               callback: @escaping ((Error?) -> Void)) {
        currentUserSessionTask = task

        task.signOutWithIdToken(idToken: idToken) { [weak self] _, error in
            defer { self?.currentUserSessionTask = nil }
            callback(error)
        }
    }

    // Holds the browser session
    var currentUserSessionTask: OktaOidcBrowserTask?
}
