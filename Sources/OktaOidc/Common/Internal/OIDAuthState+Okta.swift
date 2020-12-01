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

#if SWIFT_PACKAGE
import OktaOidc_AppAuth
#endif

// Okta Extension of OIDAuthState
extension OKTAuthState {

    static func getState(withAuthRequest authRequest: OKTAuthorizationRequest, delegate: OktaNetworkRequestCustomizationDelegate? = nil, callback: @escaping (OKTAuthState?, OktaOidcError?) -> Void ) {
        
        let finalize: ((OKTAuthState?, OktaOidcError?) -> Void) = { state, error in
            callback(state, error)
        }

        // Make authCode request
        OKTAuthorizationService.perform(authRequest: authRequest, delegate: delegate, callback: { authResponse, error in
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
            OKTAuthorizationService.perform(tokenRequest, originalAuthorizationResponse: authResponse, delegate: delegate, callback:
            { tokenResponse, error in
                guard let tokenResponse = tokenResponse else {
                    finalize(nil, OktaOidcError.APIError("Authorization Error: \(error!.localizedDescription)"))
                    return
                }

                let authState = OKTAuthState(authorizationResponse: authResponse, tokenResponse: tokenResponse)
                finalize(authState, nil)
            })
        })
    }
}
