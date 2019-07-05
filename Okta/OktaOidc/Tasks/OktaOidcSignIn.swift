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

class OktaOidcSignInTask: OktaOidcTask<OIDAuthState>, OktaOidcUserSessionTask {

    private let presenter: UIViewController
    private(set) var userAgentSession: OIDExternalUserAgentSession?
    
    init(presenter: UIViewController, config: OktaOidcConfig, oktaAPI: OktaOidcHttpApiProtocol) {
        self.presenter = presenter
        super.init(config: config, oktaAPI: oktaAPI)
    }

    override func run(callback: @escaping (OIDAuthState?, OktaOidcError?) -> Void) {
        OktaOidcMetadataDiscovery(config: config, oktaAPI: oktaAPI).run { oidConfig, error in
            guard let oidConfig = oidConfig else {
                callback(nil, error)
                return
            }

            // Build the Authentication request
            let request = OIDAuthorizationRequest(
                       configuration: oidConfig,
                            clientId: self.config.clientId,
                              scopes: OktaOidcUtils.scrubScopes(self.config.scopes),
                         redirectURL: self.config.redirectUri,
                        responseType: OIDResponseTypeCode,
                additionalParameters: self.config.additionalParams
            )

            // Start the authorization flow
            let externalUserAgent = OIDExternalUserAgentIOS(presenting: self.presenter)
            self.userAgentSession = OIDAuthState.authState(byPresenting: request, externalUserAgent: externalUserAgent!) {
                authorizationResponse, error in
                
                defer { self.userAgentSession = nil }

                guard let authResponse = authorizationResponse else {
                    return callback(nil, OktaOidcError.APIError("Authorization Error: \(error!.localizedDescription)"))
                }
                callback(authResponse, nil)
            }
        }
    }
}
