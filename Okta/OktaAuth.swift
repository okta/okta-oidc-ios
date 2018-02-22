/*
 * Copyright (c) 2017, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */
import AppAuth
import Hydra

public struct OktaAuthorization {

    func authCodeFlow(_ config: [String: Any], _ view: UIViewController) -> Promise<OktaTokenManager> {
        return Promise<OktaTokenManager>(in: .background, { resolve, reject, _ in
            // Discover Endpoints
            self.getMetadataConfig(URL(string: config["issuer"] as! String))
            .then { oidConfig in
                // Build the Authentication request
                let request = OIDAuthorizationRequest(
                           configuration: oidConfig,
                                clientId: config["clientId"] as! String,
                                  scopes: Utils.scrubScopes(config["scopes"]),
                             redirectURL: URL(string: config["redirectUri"] as! String)!,
                            responseType: OIDResponseTypeCode,
                    additionalParameters: nil
                )

                // Start the authorization flow
                OktaAuth.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, presenting: view){
                    authorizationResponse, error in
                    
                    if authorizationResponse != nil {
                        // Return the tokens
                        return resolve(OktaTokenManager(authState: authorizationResponse))
                    } else {
                        return reject(OktaError.APIError("Authorization Error: \(error!.localizedDescription)"))
                    }
                }
            }
            .catch { error in return reject(error) }
        })
    }

    func passwordFlow(_ config: [String: Any], credentials: [String: String]?, _ view: UIViewController) -> Promise<OktaTokenManager> {
        return Promise<OktaTokenManager>(in: .background, { resolve, reject, _ in
            // Discover Endpoints
            self.getMetadataConfig(URL(string: config["issuer"] as! String))
            .then { oidConfig in
                // Build the Authentication request
                let request = OIDTokenRequest(
                               configuration: oidConfig,
                                   grantType: OIDGrantTypePassword,
                           authorizationCode: nil,
                                 redirectURL: URL(string: config["redirectUri"] as! String)!,
                                    clientID: config["clientId"] as! String,
                                clientSecret: (config["clientSecret"] as! String),
                                       scope: Utils.scrubScopes(config["scopes"]).joined(separator: " "),
                                refreshToken: nil,
                                codeVerifier: nil,
                        additionalParameters: credentials
                    )

                // Start the authorization flow
                OIDAuthorizationService.perform(request) { authorizationResponse, responseError in
                    if responseError != nil {
                        return reject(OktaError.APIError("Authorization Error: \(responseError!.localizedDescription)"))
                    }

                    if authorizationResponse != nil {
                        // Return the tokens
                        let authState = OIDAuthState(
                                authorizationResponse: nil,
                                        tokenResponse: authorizationResponse,
                                 registrationResponse: nil
                            )
                        return resolve(OktaTokenManager(authState: authState))
                    }
                }
            }
            .catch { error in return reject(error) }
        })
    }

    func getMetadataConfig(_ issuer: URL?) -> Promise<OIDServiceConfiguration> {
        // Get the metadata from the discovery endpoint
        return Promise<OIDServiceConfiguration>(in: .background, { resolve, reject, _ in
            guard let issuer = issuer, let configUrl = URL(string: "\(issuer)/.well-known/openid-configuration") else {
                return reject(OktaError.NoDiscoveryEndpoint)
            }

            OktaApi.get(configUrl, headers: nil)
            .then { response in
                guard let dictResponse = response, let oidcConfig = try? OIDServiceDiscovery(dictionary: dictResponse) else {
                    return reject(OktaError.ParseFailure)
                }
                return resolve(OIDServiceConfiguration(discoveryDocument: oidcConfig))
            }
            .catch { error in
                let responseError =
                    "Error returning discovery document: \(error.localizedDescription) Please" +
                    "check your PList configuration"
                return reject(OktaError.APIError(responseError))
            }
        })
    }
}
