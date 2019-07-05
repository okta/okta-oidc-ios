/*
 * Copyright (c) 2018-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

class OktaOidcSignOutTask: OktaOidcTask<Void>, OktaOidcUserSessionTask {
    private let idToken: String
    private let presenter: UIViewController
    private(set) var userAgentSession: OIDExternalUserAgentSession?
    
    init(idToken: String, presenter: UIViewController, config: OktaOidcConfig, oktaAPI: OktaOidcHttpApiProtocol) {
        self.idToken = idToken
        self.presenter = presenter
        super.init(config: config, oktaAPI: oktaAPI)
    }

    override func run(callback: @escaping (Void?, OktaOidcError?) -> Void) {
        guard let logoutRedirectUri = config.logoutRedirectUri,
              let additionalParams = config.additionalParams else {
                callback(nil, OktaOidcError.missingConfigurationValues)
                return
        }

        OktaOidcMetadataDiscovery(config: config, oktaAPI: oktaAPI).run { oidConfig, error in
            guard let oidConfig = oidConfig else {
                callback(nil, error)
                return
            }
            
            let request = OIDEndSessionRequest(
                configuration: oidConfig,
                idTokenHint: self.idToken,
                postLogoutRedirectURL: logoutRedirectUri,
                additionalParameters: additionalParams
            )

            let agent = OIDExternalUserAgentIOS(presenting: self.presenter)

            // Present the Sign Out flow
            self.userAgentSession = OIDAuthorizationService.present(request, externalUserAgent: agent!) {
                response, responseError in
                
                defer { self.userAgentSession = nil }
                
                var error: OktaOidcError? = nil
                if let responseError = responseError {
                    error = OktaOidcError.APIError("Sign Out Error: \(responseError.localizedDescription)")
                }
                
                callback((), error)
            }
        }
    }
}
