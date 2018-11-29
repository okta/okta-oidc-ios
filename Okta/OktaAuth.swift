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

    func authCodeFlow(_ config: [String: String], _ view: UIViewController) -> Promise<OktaTokenManager> {
        return Promise<OktaTokenManager>(in: .background, { resolve, reject, _ in
            // Discover Endpoints
            guard let issuer = config["issuer"], let clientId = config["clientId"],
                let redirectUri = config["redirectUri"] else {
                    return reject(OktaError.missingConfigurationValues)
            }

            self.getMetadataConfig(URL(string: issuer))
            .then { oidConfig in
                // Build the Authentication request
                let request = OIDAuthorizationRequest(
                           configuration: oidConfig,
                                clientId: clientId,
                                  scopes: Utils.scrubScopes(config["scopes"]),
                             redirectURL: URL(string: redirectUri)!,
                            responseType: OIDResponseTypeCode,
                    additionalParameters: Utils.parseAdditionalParams(config)
                )

                // Start the authorization flow
                OktaAuth.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, presenting: view){
                    authorizationResponse, error in

                    guard let authResponse = authorizationResponse else {
                        return reject(OktaError.APIError("Authorization Error: \(error!.localizedDescription)"))
                    }
                    do {
                        let tokenManager = try OktaTokenManager(authState: authResponse, config: config, validationOptions: nil)

                        // Set the local cache and write to storage
                        self.storeAuthState(tokenManager)
                        return resolve(tokenManager)
                    } catch let error {
                        return reject(error)
                    }
                }
            }
            .catch { error in return reject(error) }
        })
    }

    func passwordFlow(_ config: [String: String], credentials: [String: String]?, _ view: UIViewController) -> Promise<OktaTokenManager> {
        return buildAndPerformTokenRequest(config, additionalParams: credentials)
    }

    func refreshTokensManually(_ config: [String: String], refreshToken: String) -> Promise<OktaTokenManager> {
        return buildAndPerformTokenRequest(config, refreshToken: refreshToken)
    }

    func buildAndPerformTokenRequest(_ config: [String: String], refreshToken: String? = nil, authCode: String? = nil,
                                     additionalParams: [String: String]? = nil) -> Promise<OktaTokenManager> {
        return Promise<OktaTokenManager>(in: .background, { resolve, reject, _ in
            // Discover Endpoints
            guard let issuer = config["issuer"],
                let clientId = config["clientId"],
                let clientSecret = config["clientSecret"],
                let redirectUri = config["redirectUri"] else {
                    return reject(OktaError.missingConfigurationValues)
            }

            self.getMetadataConfig(URL(string: issuer))
            .then { oidConfig in
                var grantType = OIDGrantTypePassword
                if refreshToken == nil && authCode == nil {
                    // Use the password grant type
                } else {
                    // If there is a refreshToken use the refesh_token grant type
                    // otherwise use the authorization_code grant
                    grantType = refreshToken != nil ? OIDGrantTypeRefreshToken : OIDGrantTypeAuthorizationCode
                }
                // Build the Authentication request
                let request = OIDTokenRequest(
                           configuration: oidConfig,
                               grantType: grantType,
                       authorizationCode: authCode,
                             redirectURL: URL(string: redirectUri)!,
                                clientID: clientId,
                            clientSecret: clientSecret,
                                  scopes: Utils.scrubScopes(config["scopes"]),
                            refreshToken: refreshToken,
                            codeVerifier: nil,
                    additionalParameters: additionalParams
                )

                // Start the authorization flow
                OIDAuthorizationService.perform(request) { authorizationResponse, responseError in
                    if responseError != nil {
                        return reject(OktaError.APIError("Authorization Error: \(responseError!.localizedDescription)"))
                    }

                    if authorizationResponse != nil {
                        let authState = OIDAuthState(
                            authorizationResponse: nil,
                                    tokenResponse: authorizationResponse,
                             registrationResponse: nil
                        )

                        do {
                            let tokenManager = try OktaTokenManager(authState: authState, config: config, validationOptions: nil)

                            // Set the local cache and write to storage
                            self.storeAuthState(tokenManager)
                            return resolve(tokenManager)
                        } catch let error {
                            return reject(error)
                        }
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
                return reject(OktaError.noDiscoveryEndpoint)
            }

            OktaApi.get(configUrl, headers: nil)
            .then { response in
                guard let dictResponse = response, let oidcConfig = try? OIDServiceDiscovery(dictionary: dictResponse) else {
                    return reject(OktaError.parseFailure)
                }
                // Cache the well-known endpoint response
                OktaAuth.wellKnown = dictResponse
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

    func storeAuthState(_ tokenManager: OktaTokenManager) {
        // Encode and store the current auth state and
        // cache the current tokens
        OktaAuth.tokens = tokenManager

        let authStateData = NSKeyedArchiver.archivedData(withRootObject: tokenManager)
        do {
            try Keychain.set(key: "OktaAuthStateTokenManager", value: authStateData, accessibility: tokenManager.accessibility)
        } catch let error {
            print("Error: \(error)")
        }
    }
}
