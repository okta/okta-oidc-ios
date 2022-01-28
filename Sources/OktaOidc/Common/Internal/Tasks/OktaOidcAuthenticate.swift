/*
 * Copyright (c) 2019-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

class OktaOidcAuthenticateTask: OktaOidcTask {
    
    func authenticateWithSessionToken(sessionToken: String,
                                      delegate: OktaNetworkRequestCustomizationDelegate? = nil,
                                      validator: OKTTokenValidator,
                                      callback: @escaping (OKTAuthState?, OktaOidcError?) -> Void) {
        self.downloadOidcConfiguration() { oidConfig, error in
            guard let oidConfig = oidConfig else {
                callback(nil, error)
                return
            }
            
            let codeVerifier = OKTAuthorizationRequest.generateCodeVerifier()
            let codeChallenge = OKTAuthorizationRequest.codeChallengeS256(forVerifier: codeVerifier)
            let state = OKTAuthorizationRequest.generateState()
            var additionalParameters = self.config.additionalParams ?? [String: String]()
            additionalParameters["sessionToken"] = sessionToken
            
            let request = OKTAuthorizationRequest(
                configuration: oidConfig,
                clientId: self.config.clientId,
                clientSecret: nil,
                scope: self.config.scopes,
                redirectURL: self.config.redirectUri,
                responseType: OKTResponseTypeCode,
                state: state,
                nonce: OKTAuthorizationRequest.generateState(),
                codeVerifier: codeVerifier,
                codeChallenge: codeChallenge,
                codeChallengeMethod: OKTOAuthorizationRequestCodeChallengeMethodS256,
                additionalParameters: additionalParameters
            )
            
            OKTAuthState.getState(withAuthRequest: request, delegate: delegate, validator: validator, callback: { authState, error in
                callback(authState, error)
            })
        }
    }
}
