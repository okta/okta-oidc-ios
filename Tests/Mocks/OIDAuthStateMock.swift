/*
* Copyright (c) 2020, Okta, Inc. and/or its affiliates. All rights reserved.
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
@testable import OktaOidc

class OIDAuthStateMock: OIDAuthState {
    class override func authState(byPresenting authorizationRequest: OIDAuthorizationRequest,
                                  externalUserAgent: OIDExternalUserAgent,
                                  delegate: OktaNetworkRequestCustomizationDelegate?,
                                  callback: @escaping OIDAuthStateAuthorizationCallback) -> OIDExternalUserAgentSession {
        DispatchQueue.main.async {
            let authState = TestUtils.setupMockAuthState(issuer: TestUtils.mockIssuer, clientId: TestUtils.mockClientId)
            callback(authState, nil)
        }
        return OIDExternalUserAgentSessionMock(signCallback: callback, signOutCallback: nil)
    }
}
