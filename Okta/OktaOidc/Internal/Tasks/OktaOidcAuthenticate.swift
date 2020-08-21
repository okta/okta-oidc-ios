/*
 * Copyright (c) 2019, Okta, Inc. and/or its affiliates. All rights reserved.
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

class OktaOidcAuthenticateTask: OktaOidcTask {
    
    func authenticateWithSessionToken(sessionToken: String,
                                      delegate: OktaNetworkRequestCustomizationDelegate? = nil,
                                      callback: @escaping (OIDAuthState?, OktaOidcError?) -> Void) {
        self.downloadOidcConfiguration() { oidConfig, error in
            guard let oidConfig = oidConfig else {
                callback(nil, error)
                return
            }
            
            let codeVerifier = OIDAuthorizationRequest.generateCodeVerifier()
            let codeChallenge = OIDAuthorizationRequest.codeChallengeS256(forVerifier: codeVerifier)
            let state = OIDAuthorizationRequest.generateState()
            var additionalParameters = self.config.additionalParams ?? [String : String]()
            additionalParameters["sessionToken"] = sessionToken
            
            let request = OIDAuthorizationRequest(
                configuration: oidConfig,
                clientId: self.config.clientId,
                clientSecret: nil,
                scope: self.config.scopes,
                redirectURL: self.config.redirectUri,
                responseType: OIDResponseTypeCode,
                state: state,
                nonce: OIDAuthorizationRequest.generateState(),
                codeVerifier: codeVerifier,
                codeChallenge: codeChallenge,
                codeChallengeMethod: OIDOAuthorizationRequestCodeChallengeMethodS256,
                additionalParameters: additionalParameters
            )
            
            OIDAuthState.getState(withAuthRequest: request, delegate: delegate, callback: { authState, error in
                callback(authState, error)
            })
        }
    }
}
