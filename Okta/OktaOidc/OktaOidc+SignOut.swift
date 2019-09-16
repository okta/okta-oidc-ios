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

internal extension OktaOidc {
    func signOut(with options: OktaSignOutOptions,
                 authStateManager: OktaOidcStateManager,
                 from presenter: UIViewController,
                 failedOptions: OktaSignOutOptions,
                 progressHandler: @escaping ((OktaSignOutOptions) -> Void),
                 completionHandler: @escaping ((Bool, OktaSignOutOptions) -> Void)) {
        if options.isEmpty {
            completionHandler(failedOptions.isEmpty, failedOptions)
            return
        }
        
        var notFinishedOptions: OktaSignOutOptions = options
        var failedOptions: OktaSignOutOptions = failedOptions
        if options.contains(.revokeAccessToken) {
            progressHandler(.revokeAccessToken)
            authStateManager.revoke(authStateManager.accessToken) { (success, error) in
                notFinishedOptions.remove(.revokeAccessToken)
                if !success {
                    failedOptions.insert(.revokeAccessToken)
                }
                self.signOut(with: notFinishedOptions,
                             authStateManager: authStateManager,
                             from: presenter,
                             failedOptions: failedOptions,
                             progressHandler: progressHandler,
                             completionHandler: completionHandler)
            }
            return
        }
        
        if options.contains(.revokeRefreshToken) {
            progressHandler(.revokeRefreshToken)
            authStateManager.revoke(authStateManager.refreshToken) { (success, error) in
                notFinishedOptions.remove(.revokeRefreshToken)
                if !success {
                    failedOptions.insert(.revokeRefreshToken)
                }
                self.signOut(with: notFinishedOptions,
                             authStateManager: authStateManager,
                             from: presenter,
                             failedOptions: failedOptions,
                             progressHandler: progressHandler,
                             completionHandler: completionHandler)
            }
            return
        }

        if options.contains(.removeTokensFromStorage) {
            notFinishedOptions.remove(.removeTokensFromStorage)
            if failedOptions.isEmpty {
                progressHandler(.removeTokensFromStorage)
                try? authStateManager.removeFromSecureStorage()
            }

            self.signOut(with: notFinishedOptions,
                         authStateManager: authStateManager,
                         from: presenter,
                         failedOptions: failedOptions,
                         progressHandler: progressHandler,
                         completionHandler: completionHandler)
            
            return
        }

        if options.contains(.signOutFromOkta) {
            progressHandler(.signOutFromOkta)
            self.signOutOfOkta(authStateManager, from: presenter) { error in
                notFinishedOptions.remove(.signOutFromOkta)
                if let _ = error {
                    failedOptions.insert(.signOutFromOkta)
                }
                self.signOut(with: notFinishedOptions,
                             authStateManager: authStateManager,
                             from: presenter,
                             failedOptions: failedOptions,
                             progressHandler: progressHandler,
                             completionHandler: completionHandler)
            }
            return
        }
    }
}
