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

#if SWIFT_PACKAGE
import OktaOidc_AppAuth
#endif

// Okta Extension of OIDAuthState
extension OKTAuthState {

    static func getState(withAuthRequest authRequest: OKTAuthorizationRequest, delegate: OktaNetworkRequestCustomizationDelegate? = nil, validator: OKTTokenValidator, callback finalize: @escaping (OKTAuthState?, OktaOidcError?) -> Void ) {
        
        // Make authCode request
        OKTAuthorizationService.perform(authRequest: authRequest, delegate: delegate) { authResponse, error in
            guard let authResponse = authResponse else {
                finalize(nil, .api(message: "Authorization Error: \(error?.localizedDescription ?? "No authentication response.")", underlyingError: error))
                return
            }
            
            if let oauthError = authResponse.additionalParameters?[OKTOAuthErrorFieldError] as? String {
                let oauthErrorDescription = authResponse.additionalParameters?[OKTOAuthErrorFieldErrorDescription] as? String
                finalize(nil, .authorization(error: oauthError, description: oauthErrorDescription))
                return
            }
            
            guard authResponse.authorizationCode != nil,
                  let tokenRequest = authResponse.tokenExchangeRequest() else {
                    finalize(nil, .unableToGetAuthCode)
                    return
            }

            // Make token request
            OKTAuthorizationService.perform(tokenRequest,
                                            originalAuthorizationResponse: authResponse,
                                            delegate: delegate,
                                            validator: validator) { tokenResponse, error in
                guard let tokenResponse = tokenResponse else {
                    finalize(nil, OktaOidcError.api(message: "Authorization Error: \(error?.localizedDescription ?? "No token response.")", underlyingError: error))
                    return
                }
                
                if let oauthError = tokenResponse.additionalParameters?[OKTOAuthErrorFieldError] as? String {
                    let oauthErrorDescription = tokenResponse.additionalParameters?[OKTOAuthErrorFieldErrorDescription] as? String
                    finalize(nil, .authorization(error: oauthError, description: oauthErrorDescription))
                    return
                }

                let authState = OKTAuthState(authorizationResponse: authResponse,
                                             tokenResponse: tokenResponse,
                                             registrationResponse: nil,
                                             delegate: delegate,
                                             validator: validator)
                finalize(authState, nil)
            }
        }
    }
}
