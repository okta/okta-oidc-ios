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

class OktaOidcNativeSSOTask: OktaOidcTask {
    
    func signIn(idToken: String, deviceSecret: String,
                callback: @escaping ((OKTAuthState?, OktaOidcError?) -> Void)) {
        self.downloadOidcConfiguration() { oidConfig, error in
            guard let oidConfiguration = oidConfig else {
                callback(nil, error)
                return
            }
            
            //Native SSO Request
            let nativeSSORequest = OKTTokenRequest(configuration: oidConfiguration,
                                                   clientID: self.config.clientId,
                                                   scopes: OktaOidcUtils.scrubNativeSSOScopes(self.config.scopes),
                                                   actorToken: deviceSecret,
                                                   subjectToken: idToken,
                                                   audience:self.config.nativeSSODomain,
                                                   additionalParameters: self.config.additionalParams)
            
                self.authStateClass().initWith(nativeSSORequest) { authState, error in
                callback(authState, nil)
            }
            

        }
    }
    
    func authStateClass() -> OKTAuthState.Type {
        return OKTAuthState.self
    }

    func authorizationServiceClass() -> OKTAuthorizationService.Type {
        return OKTAuthorizationService.self
    }
}
