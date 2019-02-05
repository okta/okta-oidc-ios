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
import Hydra

public struct OktaAuthorization {

    func authCodeFlow(_ config: [String: String], _ view: UIViewController) -> Promise<OktaTokenManager> {
        return Promise<OktaTokenManager>(in: .background, { resolve, reject, _ in
            // Discover Endpoints
            guard let issuer = config["issuer"], let clientId = config["clientId"],
                let redirectUriString = config["redirectUri"],
                let redirectUri = URL(string: redirectUriString) else {
                    return reject(OktaError.missingConfigurationValues)
            }

            self.getMetadataConfig(URL(string: issuer))
            .then { oidConfig in
                // Build the Authentication request
                let request = OIDAuthorizationRequest(
                           configuration: oidConfig,
                                clientId: clientId,
                                  scopes: Utils.scrubScopes(config["scopes"]),
                             redirectURL: redirectUri,
                            responseType: OIDResponseTypeCode,
                    additionalParameters: Utils.parseAdditionalParams(config)
                )

                // Start the authorization flow
                let externalUserAgent = OIDExternalUserAgentIOS(presenting: view)!
                OktaAuth.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, externalUserAgent: externalUserAgent) {
                    authorizationResponse, error in

                    guard let authResponse = authorizationResponse else {
                        return reject(OktaError.APIError("Authorization Error: \(error!.localizedDescription)"))
                    }
                    do {
                        let tokenManager = try OktaTokenManager(authState: authResponse, config: config)

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

    func signOut(_ config: [String: String], view: UIViewController) -> Promise<Void> {
        return Promise<Void>(in: .background, { resolve, reject, _ in
            guard let issuer = config["issuer"],
                  let logoutRedirectUriString = config["logoutRedirectUri"],
                  let logoutRedirectURL = URL(string: logoutRedirectUriString) else {
                    return reject(OktaError.missingConfigurationValues)
            }

            guard let idToken = OktaAuth.tokens?.authState.lastTokenResponse?.idToken else {
                return reject(OktaError.missingIdToken)
            }

            self.getMetadataConfig(URL(string: issuer))
            .then { oidConfig in
                let request = OIDEndSessionRequest(
                    configuration: oidConfig,
                    idTokenHint: idToken,
                    postLogoutRedirectURL: logoutRedirectURL,
                    additionalParameters: nil
                )

                let agent = OIDExternalUserAgentIOS(presenting: view)!

                // Present the Sign Out flow

                OktaAuth.currentAuthorizationFlow =
                    OIDAuthorizationService.present(request, externalUserAgent: agent) { response, responseError in
                        if let responseError = responseError {
                            return reject(OktaError.APIError("Sign Out Error: \(responseError.localizedDescription)"))
                        }
                        return resolve(())
                    }
            }
            .catch { error in
                return reject(error)
            }
        })
    }
    
    func authenticate(withSessionToken sessionToken: String, config: [String: String]) -> Promise<OktaTokenManager> {
        return Promise<OktaTokenManager>(in: .background, { resolve, reject, _ in
            // Discover Endpoints
            guard let issuer = config["issuer"],
                  let clientId = config["clientId"],
                  let redirectUriString = config["redirectUri"],
                  let redirectUri = URL(string: redirectUriString) else {
                    return reject(OktaError.missingConfigurationValues)
            }

            self.getMetadataConfig(URL(string: issuer))
            .then { oidConfig in
                let codeVerifier = OIDAuthorizationRequest.generateCodeVerifier()!
                let codeChallenge = OIDAuthorizationRequest.codeChallengeS256(forVerifier: codeVerifier)
                let state = OIDAuthorizationRequest.generateState()

                let request = OIDAuthorizationRequest(
                    configuration: oidConfig,
                    clientId: clientId,
                    clientSecret: nil,
                    scope: config["scopes"],
                    redirectURL: redirectUri,
                    responseType: OIDResponseTypeCode,
                    state: state,
                    nonce: nil,
                    codeVerifier: codeVerifier,
                    codeChallenge: codeChallenge,
                    codeChallengeMethod: OIDOAuthorizationRequestCodeChallengeMethodS256,
                    additionalParameters: ["sessionToken" : sessionToken]
                )
                
                OIDAuthState.getState(withAuthRequest: request)
                .then { authState in
                    do {
                        let tokenManager = try OktaTokenManager(authState: authState, config: config)

                        // Set the local cache and write to storage
                        OktaAuth.tokens = tokenManager
                        self.storeAuthState(tokenManager)
                
                        return resolve(tokenManager)
                    } catch let error {
                        return reject(error)
                    }
                }
                .catch { error in return reject(error) }
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

        tokenManager.writeToSecureStorage()
    }
}
