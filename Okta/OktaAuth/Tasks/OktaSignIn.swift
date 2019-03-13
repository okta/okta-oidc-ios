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

class SignInTask: OktaAuthTask<OktaTokenManager> {

    private let presenter: UIViewController
    
    init(presenter: UIViewController, config: OktaAuthConfig, oktaAPI: OktaHttpApiProtocol) {
        self.presenter = presenter
        super.init(config: config, oktaAPI: oktaAPI)
    }

    override func run(callback: @escaping (OktaTokenManager?, OktaError?) -> Void) {
        MetadataDiscovery(config: config, oktaAPI: oktaAPI).run { oidConfig, error in
            guard let oidConfig = oidConfig else {
                callback(nil, error)
                return
            }

            // Build the Authentication request
            let request = OIDAuthorizationRequest(
                       configuration: oidConfig,
                            clientId: self.config.clientId,
                              scopes: Utils.scrubScopes(self.config.scopes),
                         redirectURL: self.config.redirectUri,
                        responseType: OIDResponseTypeCode,
                additionalParameters: self.config.additionalParams
            )

            // Start the authorization flow
            let externalUserAgent = OIDExternalUserAgentIOS(presenting: self.presenter)
            OktaAuth.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, externalUserAgent: externalUserAgent) {
                authorizationResponse, error in

                guard let authResponse = authorizationResponse else {
                    return callback(nil, OktaError.APIError("Authorization Error: \(error!.localizedDescription)"))
                }

                let tokenManager = OktaTokenManager(authState: authResponse, config: self.config)

                OktaAuth.tokenManager = tokenManager

                callback(tokenManager, nil)
            }
        }
    }
}
