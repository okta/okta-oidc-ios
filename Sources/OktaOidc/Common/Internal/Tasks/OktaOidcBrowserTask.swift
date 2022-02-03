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

import Foundation

#if SWIFT_PACKAGE
import OktaOidc_AppAuth
#endif

class OktaOidcBrowserTask: OktaOidcTask {

    var userAgentSession: OKTExternalUserAgentSession?
    
    func signIn(delegate: OktaNetworkRequestCustomizationDelegate? = nil,
                validator: OKTTokenValidator,
                callback: @escaping ((OKTAuthState?, OktaOidcError?) -> Void)) {
        self.downloadOidcConfiguration() { oidConfig, error in
            guard let oidConfiguration = oidConfig else {
                callback(nil, error)
                return
            }

            guard let successRedirectURL = self.signInRedirectUri() else {
                callback(nil, .missingConfigurationValues)
                return
            }

            let request = OKTAuthorizationRequest(configuration: oidConfiguration,
                                                  clientId: self.config.clientId,
                                                  scopes: OktaOidcUtils.scrubScopes(self.config.scopes),
                                                  redirectURL: successRedirectURL,
                                                  responseType: OKTResponseTypeCode,
                                                  additionalParameters: self.config.additionalParams)
            guard let externalUserAgent = self.externalUserAgent() else {
                callback(nil, OktaOidcError.api(message: "Authorization Error: \(error?.localizedDescription ?? "No external User Agent.")", underlyingError: nil))
                return
            }

            let userAgentSession = self.authStateClass().authState(byPresenting: request,
                                                                   externalUserAgent: externalUserAgent,
                                                                   delegate: delegate,
                                                                   validator: validator) { authorizationResponse, error in
                defer { self.userAgentSession = nil }

                if let authResponse = authorizationResponse {
                    callback(authResponse, nil)
                    return
                }
                
                guard let error = error else {
                    callback(nil, OktaOidcError.api(message: "Authorization Error: No authorization response", underlyingError: nil))
                    return
                }
                
                if (error as NSError).code == OKTErrorCode.userCanceledAuthorizationFlow.rawValue {
                    callback(nil, OktaOidcError.userCancelledAuthorizationFlow)
                    return
                }

                if (error as NSError).code == OKTErrorCode.browserOpenError.rawValue {
                    callback(nil, OktaOidcError.unableToOpenBrowser)
                    return
                }
                
                return callback(nil, OktaOidcError.api(message: "Authorization Error: \(error.localizedDescription)", underlyingError: error))
            }
            self.userAgentSession = userAgentSession
        }
    }
    
    func signOutWithIdToken(idToken: String,
                            callback: @escaping (Void?, OktaOidcError?) -> Void) {
        self.downloadOidcConfiguration() { oidConfig, error in
            guard let oidConfig = oidConfig else {
                callback(nil, error)
                return
            }

            guard let successRedirectURL = self.signOutRedirectUri() else {
                callback(nil, .missingConfigurationValues)
                return
            }

            let request = OKTEndSessionRequest(configuration: oidConfig,
                                               idTokenHint: idToken,
                                               postLogoutRedirectURL: successRedirectURL,
                                               additionalParameters: self.config.additionalParams)
            guard let externalUserAgent = self.externalUserAgent() else {
                callback(nil, OktaOidcError.api(message: "Authorization Error: \(error?.localizedDescription ?? "No external User Agent.")", underlyingError: nil))
                return
            }
            
            let userAgentSession = self.authorizationServiceClass().present(request, externalUserAgent: externalUserAgent) { _, responseError in    
                self.userAgentSession = nil
                
                var error: OktaOidcError?
                if let responseError = responseError {
                    error = OktaOidcError.api(message: "Sign Out Error: \(responseError.localizedDescription)", underlyingError: nil)
                }
                
                callback((), error)
            }
            self.userAgentSession = userAgentSession
        }
    }

    @discardableResult func resume(with url: URL) -> Bool {
        guard let userAgentSession = userAgentSession else {
            return false
        }
        
        return userAgentSession.resumeExternalUserAgentFlow(with: url)
    }

    func signInRedirectUri() -> URL? {
        return self.config.redirectUri
    }

    func signOutRedirectUri() -> URL? {
        return self.config.logoutRedirectUri
    }

    func externalUserAgent() -> OKTExternalUserAgent? {
        // override
        return nil
    }

    func authStateClass() -> OKTAuthState.Type {
        return OKTAuthState.self
    }

    func authorizationServiceClass() -> OKTAuthorizationService.Type {
        return OKTAuthorizationService.self
    }
}
