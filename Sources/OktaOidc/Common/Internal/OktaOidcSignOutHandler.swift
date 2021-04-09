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

class OktaOidcSignOutHandler {
    
    let options: OktaSignOutOptions
    let authStateManager: OktaOidcStateManager
    
    init(options: OktaSignOutOptions, authStateManager: OktaOidcStateManager) {
        self.options = options
        self.authStateManager = authStateManager
    }
    
    final func signOut(with options: OktaSignOutOptions,
                       failedOptions: OktaSignOutOptions,
                       progressHandler: @escaping ((OktaSignOutOptions) -> Void),
                       completionHandler: @escaping ((Bool, OktaSignOutOptions) -> Void)) {
        if options.isEmpty {
            completionHandler(failedOptions.isEmpty, failedOptions)
            return
        }
        
        var notFinishedOptions: OktaSignOutOptions = options
        var failedOptions: OktaSignOutOptions = failedOptions
        
        // Access Token
        if options.contains(.revokeAccessToken) {
            progressHandler(.revokeAccessToken)
            authStateManager.revoke(authStateManager.accessToken) { (success, _) in
                notFinishedOptions.remove(.revokeAccessToken)
                if !success {
                    failedOptions.insert(.revokeAccessToken)
                }
                
                self.signOut(with: notFinishedOptions,
                             failedOptions: failedOptions,
                             progressHandler: progressHandler,
                             completionHandler: completionHandler)
            }
            
            return
        }
        
        // Refresh Token
        if options.contains(.revokeRefreshToken) {
            progressHandler(.revokeRefreshToken)
            
            // Refresh token is not required in Admin panel
            guard let refreshToken = authStateManager.refreshToken, !refreshToken.isEmpty  else {
                notFinishedOptions.remove(.revokeRefreshToken)
                signOut(with: notFinishedOptions,
                        failedOptions: failedOptions,
                        progressHandler: progressHandler,
                        completionHandler: completionHandler)
                
                return
            }
            
            authStateManager.revoke(refreshToken) { (success, _) in
                notFinishedOptions.remove(.revokeRefreshToken)
                if !success {
                    failedOptions.insert(.revokeRefreshToken)
                }
                
                self.signOut(with: notFinishedOptions,
                             failedOptions: failedOptions,
                             progressHandler: progressHandler,
                             completionHandler: completionHandler)
            }
            
            return
        }
        
        // Sign out
        if options.contains(.signOutFromOkta) {
            signOutOfOkta(with: notFinishedOptions,
                          failedOptions: failedOptions,
                          progressHandler: progressHandler,
                          completionHandler: completionHandler)
            return
        }
        
        // Remove cached tokens
        if options.contains(.removeTokensFromStorage) {
            notFinishedOptions.remove(.removeTokensFromStorage)
            if failedOptions.isEmpty {
                progressHandler(.removeTokensFromStorage)
                try? authStateManager.removeFromSecureStorage()
            }
            
            signOut(with: notFinishedOptions,
                    failedOptions: failedOptions,
                    progressHandler: progressHandler,
                    completionHandler: completionHandler)
            
            return
        }
    }
    
    func signOutOfOkta(with options: OktaSignOutOptions,
                       failedOptions: OktaSignOutOptions,
                       progressHandler: @escaping ((OktaSignOutOptions) -> Void),
                       completionHandler: @escaping ((Bool, OktaSignOutOptions) -> Void)) {
        // override
        var notFinishedOptions: OktaSignOutOptions = options
        notFinishedOptions.remove(.signOutFromOkta)
        progressHandler(.signOutFromOkta)
        
        signOut(with: notFinishedOptions,
                failedOptions: failedOptions,
                progressHandler: progressHandler,
                completionHandler: completionHandler)
    }
}
