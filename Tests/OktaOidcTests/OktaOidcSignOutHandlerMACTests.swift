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

@testable import OktaOidc
import XCTest

#if SWIFT_PACKAGE
@testable import TestCommon
#endif

#if os(macOS)

class OktaOidcSignOutHandlerMACTests: XCTestCase {

    func testOktaOidcSignOutHandlerMACCreation() {
        guard let oidc = try? OktaOidc(configuration: createTestConfig()) else {
            XCTFail("Failed to create oidc object")
            return
        }

        let authStateManager = OktaOidcStateManager(
            authState: TestUtils.setupMockAuthState(issuer: TestUtils.mockIssuer, clientId: TestUtils.mockClientId)
        )
        let signOutHandler = OktaOidcSignOutHandlerMAC(options: .allOptions,
                                                       oidcClient: oidc,
                                                       authStateManager: authStateManager,
                                                       redirectServerConfiguration: OktaRedirectServerConfiguration.default)
        XCTAssertNotNil(signOutHandler.redirectServerConfiguration)
    }

    func testSignOutOfOktaMethod() {
        let authStateManager = OktaOidcStateManager(
            authState: TestUtils.setupMockAuthState(issuer: TestUtils.mockIssuer, clientId: TestUtils.mockClientId)
        )
        let signOutHandler = OktaOidcSignOutHandlerMAC(options: .allOptions,
                                                       oidcClient: OktaOidcMacMock(),
                                                       authStateManager: authStateManager,
                                                       redirectServerConfiguration: OktaRedirectServerConfiguration.default)
        XCTAssertNotNil(signOutHandler.redirectServerConfiguration)
        let progressExpectation = expectation(description: "Progress should be called!")
        let completionExpectation = expectation(description: "Completion should be called!")
        signOutHandler.signOutOfOkta(
            with: .signOutFromOkta,
            failedOptions: .signOutFromOkta,
            progressHandler: { signOutOptions in
                XCTAssertEqual(.signOutFromOkta, signOutOptions)
                progressExpectation.fulfill()
            }) { _, _ in
            completionExpectation.fulfill()
        }

        wait(for: [progressExpectation, completionExpectation], timeout: 5.0)
    }

    func createTestConfig() -> OktaOidcConfig? {
        let dict = [
            "clientId": "test_client_id",
            "issuer": "test_issuer",
            "scopes": "test_scope",
            "redirectUri": "com.test:/callback",
            "logoutRedirectUri": "com.test:/logout"
        ]

        do {
            return try OktaOidcConfig(with: dict)
        } catch {
            return nil
        }
    }
}

#endif
