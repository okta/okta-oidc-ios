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

class OktaOidcDeviceSecretTask: OktaOidcTask {
    
  func signInWithDeviceSecret(deviceSecret: String, subjectToken: String,
                                      delegate: OktaNetworkRequestCustomizationDelegate? = nil,
                                      callback: @escaping (OKTAuthState?, OktaOidcError?) -> Void) {
        self.downloadOidcConfiguration() { oidConfig, error in
            guard let oidConfig = oidConfig else {
                callback(nil, error)
                return
            }
            
            var additionalParameters = self.config.additionalParams ?? [String: String]()
            additionalParameters["actor_token_type"] = "urn:x-oath:params:oauth:token-type:device-secret"
            additionalParameters["subject_token_type"] = "urn:ietf:params:oauth:token-type:id_token"
          
            // device_sso scope is not allowed for the exchange, remove if present
            var scopes = self.config.scopes
            if let range = scopes.range(of: " device_sso") {
              scopes.removeSubrange(range)
            }
            if let range = scopes.range(of: "device_sso ") {
              scopes.removeSubrange(range)
            }
          
            let request = OKTTokenRequest(
              configuration: oidConfig,
              grantType: OKTGrantTypeDeviceSecret,
              authorizationCode: nil,
              redirectURL: nil,
              clientID: self.config.clientId,
              clientSecret: nil,
              scope: scopes,
              refreshToken: nil,
              codeVerifier: nil,
              deviceSecret: deviceSecret,
              subjectToken: subjectToken,
              additionalParameters: additionalParameters
            )
            
            OKTAuthState.getState(withTokenRequest: request, delegate: delegate, callback: { authState, error in
                callback(authState, error)
            })
        }
    }
}

