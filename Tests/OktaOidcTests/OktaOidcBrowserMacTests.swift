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

@testable import OktaOidc
@testable import TestCommon
import XCTest

#if os(macOS)

fileprivate class OktaOidcPartialMock: OktaOidc {
    override func signInWithBrowserTask(_ task: OktaOidcBrowserTask,
                                        callback: @escaping ((OktaOidcStateManager?, Error?) -> Void)) {
        guard let macTask = task as? OktaOidcBrowserTaskMAC else {
            assertionFailure("Expected \(OktaOidcBrowserTaskMAC.self) type.")
            return
        }
        
        DispatchQueue.main.async {
            let task = OktaOidcBrowserTaskMACFunctionalMock(config: self.configuration,
                                                            oktaAPI: OktaOidcApiMock(),
                                                            redirectServerConfiguration: macTask.redirectServerConfiguration)
            super.signInWithBrowserTask(task, callback: callback)
        }
    }

    override func signOutWithBrowserTask(_ task: OktaOidcBrowserTask, idToken: String, callback: @escaping ((Error?) -> Void)) {
        guard let macTask = task as? OktaOidcBrowserTaskMAC else {
            assertionFailure("Expected \(OktaOidcBrowserTaskMAC.self) type.")
            return
        }
        
        DispatchQueue.main.async {
            let task = OktaOidcBrowserTaskMACFunctionalMock(config: self.configuration,
                                                            oktaAPI: OktaOidcApiMock(),
                                                            redirectServerConfiguration: macTask.redirectServerConfiguration)
            super.signOutWithBrowserTask(task, idToken: idToken, callback: callback)
        }
    }
}

class OktaOidcBrowserTests: XCTestCase {

    func testSignInSuccessFlow() {
        guard let oidc = try? OktaOidcPartialMock(configuration: createTestConfig()) else {
            XCTFail("Failed to create oidc object")
            return
        }

        let signInExpectation = expectation(description: "Completion should be called!")
        oidc.signInWithBrowser(redirectServerConfiguration: OktaRedirectServerConfiguration.default) { stateManager, error in
            XCTAssertNotNil(stateManager)
            XCTAssertNotNil(stateManager?.accessToken)
            XCTAssertNotNil(stateManager?.refreshToken)
            XCTAssertNil(error)
            signInExpectation.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testSignOutSuccessFlow() {
        guard let oidc = try? OktaOidcPartialMock(configuration: createTestConfig()) else {
            XCTFail("Failed to create oidc object")
            return
        }

        let signOutExpectation = expectation(description: "Completion should be called!")
        let authStateManager = OktaOidcStateManager(
            authState: TestUtils.setupMockAuthState(issuer: TestUtils.mockIssuer, clientId: TestUtils.mockClientId)
        )
        oidc.signOutOfOkta(authStateManager: authStateManager, redirectServerConfiguration: OktaRedirectServerConfiguration.default) { error in
            XCTAssertNil(error)
            signOutExpectation.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testSignInCancelSuccessFlow() {
        guard let oidc = try? OktaOidcPartialMock(configuration: createTestConfig()) else {
            XCTFail("Failed to create oidc object")
            return
        }

        let signInExpectation = expectation(description: "Completion should be called!")
        let serverConfiguration = OktaRedirectServerConfiguration(successRedirectURL: nil, port: 60000, domainName: nil)
        oidc.signInWithBrowser(redirectServerConfiguration: serverConfiguration) { _, error in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.localizedDescription, "Authorization Error: Authorization flow was cancelled.")
            signInExpectation.fulfill()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            oidc.cancelBrowserSession()
        }

        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testSignOutCancelSuccessFlow() {
        guard let oidc = try? OktaOidcPartialMock(configuration: createTestConfig()) else {
            XCTFail("Failed to create oidc object")
            return
        }

        let signOutExpectation = expectation(description: "Completion should be called!")
        let serverConfiguration = OktaRedirectServerConfiguration(successRedirectURL: nil, port: 60000, domainName: nil)
        let authStateManager = OktaOidcStateManager(
            authState: TestUtils.setupMockAuthState(issuer: TestUtils.mockIssuer, clientId: TestUtils.mockClientId)
        )
        oidc.signOutOfOkta(authStateManager: authStateManager, redirectServerConfiguration: serverConfiguration) { error in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.localizedDescription, "Sign Out Error: Authorization flow was cancelled.")
            signOutExpectation.fulfill()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            oidc.cancelBrowserSession()
        }

        waitForExpectations(timeout: 5.0, handler: nil)
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
