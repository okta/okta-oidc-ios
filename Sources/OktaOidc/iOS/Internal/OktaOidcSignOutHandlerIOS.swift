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

#if os(iOS)

import UIKit

final class OktaOidcSignOutHandlerIOS: OktaOidcSignOutHandler {
    
    let presenter: UIViewController
    let oidcClient: OktaOidcBrowserProtocolIOS
    
    init(presenter: UIViewController, options: OktaSignOutOptions, oidcClient: OktaOidcBrowserProtocolIOS, authStateManager: OktaOidcStateManager) {
        self.presenter = presenter
        self.oidcClient = oidcClient
        
        super.init(options: options, authStateManager: authStateManager)
    }

    override func signOutOfOkta(with options: OktaSignOutOptions,
                                failedOptions: OktaSignOutOptions,
                                progressHandler: @escaping ((OktaSignOutOptions) -> Void),
                                completionHandler: @escaping ((Bool, OktaSignOutOptions) -> Void)) {
        var notFinishedOptions: OktaSignOutOptions = options
        var failedOptions: OktaSignOutOptions = failedOptions
        progressHandler(.signOutFromOkta)
        
        oidcClient.signOutOfOkta(authStateManager, from: presenter) { error in
            notFinishedOptions.remove(.signOutFromOkta)

            if error != nil {
                failedOptions.insert(.signOutFromOkta)
            }
            
            super.signOut(with: notFinishedOptions,
                          failedOptions: failedOptions,
                          progressHandler: progressHandler,
                          completionHandler: completionHandler)
        }
    }
}

#endif
