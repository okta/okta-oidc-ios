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

// Okta Extension of OIDAuthState
extension OIDAuthState {

    static func getState(withAuthRequest authRequest: OIDAuthorizationRequest, callback: @escaping (OIDAuthState?, OktaOidcError?) -> Void ) {
        
        let finalize: ((OIDAuthState?, OktaOidcError?) -> Void) = { state, error in
            callback(state, error)
        }

        // Make authCode request
        OIDAuthorizationService.perform(authRequest: authRequest, callback: { authResponse, error in
            guard let authResponse = authResponse else {
                finalize(nil, OktaOidcError.APIError("Authorization Error: \(error!.localizedDescription)"))
                return
            }

            guard let _ = authResponse.authorizationCode,
                  let tokenRequest = authResponse.tokenExchangeRequest() else {
                    finalize(nil, OktaOidcError.unableToGetAuthCode)
                    return
            }

            // Make token request
            OIDAuthorizationService.perform(tokenRequest, originalAuthorizationResponse: authResponse, callback:
            { tokenResponse, error in
                guard let tokenResponse = tokenResponse else {
                    finalize(nil, OktaOidcError.APIError("Authorization Error: \(error!.localizedDescription)"))
                    return
                }

                let authState = OIDAuthState(authorizationResponse: authResponse, tokenResponse: tokenResponse)
                finalize(authState, nil)
            })
        })
    }
}
