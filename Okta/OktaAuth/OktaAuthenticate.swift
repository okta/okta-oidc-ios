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

class AuthenticateTask: OktaAuthTask<OktaTokenManager> {

    private let sessionToken: String
    
    init(config: OktaAuthConfig?, sessionToken: String) {
        self.sessionToken = sessionToken
        super.init(config: config)
    }
    
    override func run(callback: @escaping (OktaTokenManager?, OktaError?) -> Void) {
        guard let config = configuration else {
            callback(nil, OktaError.notConfigured)
            return
        }

        guard let clientId = config.clientId,
              let redirectUri = config.redirectUri,
              let scopes = config.scopes else {
                callback(nil, OktaError.missingConfigurationValues)
                return
        }
        
        MetadataDiscovery(config: config).run { oidConfig, error in
            guard let oidConfig = oidConfig else {
                callback(nil, error)
                return
            }
            
            let codeVerifier = OIDAuthorizationRequest.generateCodeVerifier()!
            let codeChallenge = OIDAuthorizationRequest.codeChallengeS256(forVerifier: codeVerifier)
            let state = OIDAuthorizationRequest.generateState()
            
            let request = OIDAuthorizationRequest(
                configuration: oidConfig,
                clientId: clientId,
                clientSecret: nil,
                scope: scopes,
                redirectURL: redirectUri,
                responseType: OIDResponseTypeCode,
                state: state,
                nonce: nil,
                codeVerifier: codeVerifier,
                codeChallenge: codeChallenge,
                codeChallengeMethod: OIDOAuthorizationRequestCodeChallengeMethodS256,
                additionalParameters: ["sessionToken" : self.sessionToken]
            )
            
            OIDAuthState.getState(withAuthRequest: request, callback: { authState, error in
                guard let authState = authState else {
                    callback(nil, error)
                    return
                }
                
                let tokenManager = OktaTokenManager(authState: authState, config: config)
                
                // Set the local cache and write to storage
                OktaAuth.tokens = tokenManager

                callback(tokenManager, nil)
            })
        }
    }
}
