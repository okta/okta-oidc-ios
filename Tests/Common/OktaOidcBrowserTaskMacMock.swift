/*
 * Copyright (c) 2020-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

// swiftlint:disable force_try
// swiftlint:disable force_cast
// swiftlint:disable force_unwrapping

// swiftlint:disable force_try
// swiftlint:disable force_cast
// swiftlint:disable force_unwrapping

import Foundation
@testable import OktaOidc

#if os(macOS)

class OktaOidcBrowserTaskMACUnitMock: OktaOidcBrowserTaskMAC {
    var signInCalled = false
    var signOutCalled = false
    var error: OktaOidcError?
    
    override func signIn(delegate: OktaNetworkRequestCustomizationDelegate? = nil, validator: OKTTokenValidator, callback: @escaping ((OKTAuthState?, OktaOidcError?) -> Void)) {
        DispatchQueue.main.async {
            self.signInCalled = true
            if let error = self.error {
                callback(nil, error)
            } else {
                let authState = TestUtils.setupMockAuthState(issuer: TestUtils.mockIssuer, clientId: TestUtils.mockClientId)
                callback(authState, nil)
            }
        }
    }

    override func signOutWithIdToken(idToken: String, callback: @escaping (Void?, OktaOidcError?) -> Void) {
        DispatchQueue.main.async {
            self.signOutCalled = true
            if let error = self.error {
                callback(nil, error)
            } else {
                callback((), nil)
            }
        }
    }
}

class OktaOidcBrowserTaskMACFunctionalMock: OktaOidcBrowserTaskMAC {
    override func authStateClass() -> OKTAuthState.Type {
        return OKTAuthStateMACMock.self
    }

    override func authorizationServiceClass() -> OKTAuthorizationService.Type {
        return OKTAuthorizationServiceMACMock.self
    }

    override func downloadOidcConfiguration(callback: @escaping (OKTServiceConfiguration?, OktaOidcError?) -> Void) {
        DispatchQueue.main.async {
            let oidConfig = OKTServiceConfiguration(authorizationEndpoint: URL(string: "https://test.okta.com")!,
                                                    tokenEndpoint: URL(string: "https://test.okta.com")!,
                                                    issuer: URL(string: "https://test.okta.com")!,
                                                    registrationEndpoint: URL(string: "https://test.okta.com")!,
                                                    endSessionEndpoint: URL(string: "https://test.okta.com")!)
            callback(oidConfig, nil)
        }
    }
}

#endif
