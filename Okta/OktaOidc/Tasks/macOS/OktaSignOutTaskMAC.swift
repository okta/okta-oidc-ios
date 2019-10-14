/*
* Copyright (c) 2017-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

class OktaOidcSignOutTaskMAC: OktaOidcSignOutTask {

    override func authStateWith(request: OIDEndSessionRequest,
                                callback: @escaping (Void?, OktaOidcError?) -> Void) -> OIDExternalUserAgentSession? {
        let externalUserAgent = OIDExternalUserAgentMac()
        let userAgentSession = OIDAuthorizationService.present(request, externalUserAgent: externalUserAgent) {
            response, responseError in
            
            defer { self.userAgentSession = nil }
            
            var error: OktaOidcError? = nil
            if let responseError = responseError {
                error = OktaOidcError.APIError("Sign Out Error: \(responseError.localizedDescription)")
            }
            
            callback((), error)
        }

        return userAgentSession
    }
}
