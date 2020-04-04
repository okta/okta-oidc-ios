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

class OktaOidcBrowserTask: OktaOidcTask {

    var userAgentSession: OIDExternalUserAgentSession?
    
    func signIn(callback: @escaping ((OIDAuthState?, OktaOidcError?) -> Void)) {
        self.downloadOidcConfiguration() { oidConfig, error in
            guard let oidConfiguration = oidConfig else {
                callback(nil, error)
                return
            }

            guard let successRedirectURL = self.signInRedirectUri() else {
                callback(nil, .missingConfigurationValues)
                return
            }

            let request = OIDAuthorizationRequest(configuration: oidConfiguration,
                                                  clientId: self.config.clientId,
                                                  scopes: OktaOidcUtils.scrubScopes(self.config.scopes),
                                                  redirectURL: successRedirectURL,
                                                  responseType: OIDResponseTypeCode,
                                                  additionalParameters: self.config.additionalParams)
            guard let externalUserAgent = self.externalUserAgent() else {
                callback(nil, OktaOidcError.APIError("Authorization Error: \(error!.localizedDescription)"))
                return
            }

            let userAgentSession = self.authStateClass().authState(byPresenting: request,
                                                                   externalUserAgent: externalUserAgent)
            { authorizationResponse, error in
                defer { self.userAgentSession = nil }

                guard let authResponse = authorizationResponse else {
                    return callback(nil, OktaOidcError.APIError("Authorization Error: \(error!.localizedDescription)"))
                }
                callback(authResponse, nil)
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

            let request = OIDEndSessionRequest(configuration: oidConfig,
                                               idTokenHint: idToken,
                                               postLogoutRedirectURL: successRedirectURL,
                                               additionalParameters: self.config.additionalParams)
            guard let externalUserAgent = self.externalUserAgent() else {
                callback(nil, OktaOidcError.APIError("Authorization Error: \(error!.localizedDescription)"))
                return
            }
            let userAgentSession = self.authorizationServiceClass().present(request, externalUserAgent: externalUserAgent) {
                response, responseError in
                
                self.userAgentSession = nil
                
                var error: OktaOidcError? = nil
                if let responseError = responseError {
                    error = OktaOidcError.APIError("Sign Out Error: \(responseError.localizedDescription)")
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

    func externalUserAgent() -> OIDExternalUserAgent? {
        // override
        return nil
    }

    func authStateClass() -> OIDAuthState.Type {
        return OIDAuthState.self
    }

    func authorizationServiceClass() -> OIDAuthorizationService.Type {
        return OIDAuthorizationService.self
    }
}
