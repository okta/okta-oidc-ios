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

@testable import OktaOidc
@testable import TestCommon
import XCTest

#if os(macOS)

fileprivate class OktaOidcPartialMock: OktaOidc {
    var error: Error?
    
    override func signInWithBrowserTask(_ task: OktaOidcBrowserTask,
                                        callback: @escaping ((OktaOidcStateManager?, Error?) -> Void)) {
        DispatchQueue.main.async {
            if let error = self.error {
                callback(nil, error)
            } else {
                let authStateManager = OktaOidcStateManager(
                    authState: TestUtils.setupMockAuthState(issuer: TestUtils.mockIssuer, clientId: TestUtils.mockClientId)
                )
                callback(authStateManager, nil)
            }
        }
    }

    override func signOutWithBrowserTask(_ task: OktaOidcBrowserTask, idToken: String, callback: @escaping ((Error?) -> Void)) {
        DispatchQueue.main.async {
            callback(self.error)
        }
    }
}

class OktaOidcMacTests: XCTestCase {

    func testSignInWithBrowserMethod() {
        guard let oidc = try? OktaOidcPartialMock(configuration: createTestConfig()) else {
            XCTFail("Failed to create oidc object")
            return
        }

        // Validate success case
        var signInExpectation = expectation(description: "Completion should be called!")
        oidc.signInWithBrowser { stateManager, error in
            XCTAssertNil(error)
            XCTAssertNotNil(stateManager)
            signInExpectation.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssertNil(oidc.currentUserSessionTask)

        // Validate error case
        signInExpectation = expectation(description: "Completion should be called!")
        oidc.error = OktaOidcError.noDiscoveryEndpoint
        oidc.signInWithBrowser { stateManager, error in
            XCTAssertNil(stateManager)
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.localizedDescription, OktaOidcError.noDiscoveryEndpoint.localizedDescription)
            signInExpectation.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssertNil(oidc.currentUserSessionTask)
    }

    func testSignOutOfOktaMethod() {
        guard let oidc = try? OktaOidcPartialMock(configuration: createTestConfig()) else {
            XCTFail("Failed to create oidc object")
            return
        }

        // Validate success case
        var signOutExpectation = expectation(description: "Completion should be called!")
        let authStateManager = OktaOidcStateManager(
            authState: TestUtils.setupMockAuthState(issuer: TestUtils.mockIssuer, clientId: TestUtils.mockClientId)
        )
        oidc.signOutOfOkta(authStateManager: authStateManager) { error in
            XCTAssertNil(error)
            signOutExpectation.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)

        // Validate error case
        signOutExpectation = expectation(description: "Completion should be called!")
        oidc.error = OktaOidcError.noDiscoveryEndpoint
        oidc.signOutOfOkta(authStateManager: authStateManager) { error in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.localizedDescription, OktaOidcError.noDiscoveryEndpoint.localizedDescription)
            signOutExpectation.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testSignOutOfOktaMethodNoIdToken() {
        guard let oidc = try? OktaOidc(configuration: createTestConfig()) else {
            XCTFail("Failed to create oidc object")
            return
        }

        let authStateManager = OktaOidcStateManager(
            authState: TestUtils.setupMockAuthState(issuer: TestUtils.mockIssuer, clientId: TestUtils.mockClientId, skipTokenResponse: true)
        )
        oidc.signOutOfOkta(authStateManager: authStateManager) { error in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.localizedDescription, OktaOidcError.missingIdToken.localizedDescription)
        }
    }

    func testSignOutMethod() {
        guard let oidc = try? OktaOidc(configuration: createTestConfig()) else {
            XCTFail("Failed to create oidc object")
            return
        }

        let progressExpectation = expectation(description: "Progress handler should be called!")
        var signOutExpectation = expectation(description: "Completion should be called!")
        let authStateManager = OktaOidcStateManager(
            authState: TestUtils.setupMockAuthState(issuer: TestUtils.mockIssuer, clientId: TestUtils.mockClientId)
        )
        oidc.signOut(with: .signOutFromOkta, authStateManager: authStateManager, progressHandler: { _ in
            progressExpectation.fulfill()
        }) { _, _ in
            signOutExpectation.fulfill()
        }

        wait(for: [progressExpectation, signOutExpectation], timeout: 5.0)

        let revokeAccessTokenExpectation = expectation(description: "Progress handler should be called!")
        let revokeRefreshTokenExpectation = expectation(description: "Progress handler should be called!")
        signOutExpectation = expectation(description: "Completion should be called!")
        oidc.signOut(authStateManager: authStateManager, progressHandler: { options in
            if options == .revokeAccessToken {
                revokeAccessTokenExpectation.fulfill()
            } else if options == .revokeRefreshToken {
                revokeRefreshTokenExpectation.fulfill()
            }
        }) { _, _ in
            signOutExpectation.fulfill()
        }

        wait(for: [revokeAccessTokenExpectation, revokeRefreshTokenExpectation, signOutExpectation], timeout: 5.0)
    }

    func testSignInWithBrowserTaskMethod() {
        guard let oidc = try? OktaOidc(configuration: createTestConfig()) else {
            XCTFail("Failed to create oidc object")
            return
        }

        // Success case
        var signInExpectation = expectation(description: "Completion should be called!")
        var browserTaskMock = OktaOidcBrowserTaskMACUnitMock(config: createTestConfig()!, oktaAPI: OktaOidcApiMock())
        oidc.signInWithBrowserTask(browserTaskMock) { stateManager, error in
            XCTAssertNil(error)
            XCTAssertNotNil(stateManager)
            signInExpectation.fulfill()
        }

        XCTAssertNotNil(oidc.currentUserSessionTask)
        waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssertNil(oidc.currentUserSessionTask)

        // Error case
        signInExpectation = expectation(description: "Completion should be called!")
        browserTaskMock = OktaOidcBrowserTaskMACUnitMock(config: createTestConfig()!, oktaAPI: OktaOidcApiMock())
        browserTaskMock.error = OktaOidcError.noDiscoveryEndpoint
        oidc.signInWithBrowserTask(browserTaskMock) { stateManager, error in
            XCTAssertNil(stateManager)
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.localizedDescription, OktaOidcError.noDiscoveryEndpoint.localizedDescription)
            signInExpectation.fulfill()
        }

        XCTAssertNotNil(oidc.currentUserSessionTask)
        waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssertNil(oidc.currentUserSessionTask)
    }

    func testSignOutWithBrowserTaskMethod() {
        guard let oidc = try? OktaOidc(configuration: createTestConfig()) else {
            XCTFail("Failed to create oidc object")
            return
        }

        // Success case
        var signOutExpectation = expectation(description: "Completion should be called!")
        var browserTaskMock = OktaOidcBrowserTaskMACUnitMock(config: createTestConfig()!, oktaAPI: OktaOidcApiMock())
        oidc.signOutWithBrowserTask(browserTaskMock, idToken: "id_token") { error in
            XCTAssertNil(error)
            signOutExpectation.fulfill()
        }

        XCTAssertNotNil(oidc.currentUserSessionTask)
        waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssertNil(oidc.currentUserSessionTask)

        // Error case
        signOutExpectation = expectation(description: "Completion should be called!")
        browserTaskMock = OktaOidcBrowserTaskMACUnitMock(config: createTestConfig()!, oktaAPI: OktaOidcApiMock())
        browserTaskMock.error = OktaOidcError.noDiscoveryEndpoint
        oidc.signOutWithBrowserTask(browserTaskMock, idToken: "id_token") { error in
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.localizedDescription, OktaOidcError.noDiscoveryEndpoint.localizedDescription)
            signOutExpectation.fulfill()
        }

        XCTAssertNotNil(oidc.currentUserSessionTask)
        waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssertNil(oidc.currentUserSessionTask)
    }

    func testCancelBrowserSessionMethod() {
        guard let oidc = try? OktaOidc(configuration: createTestConfig()) else {
            XCTFail("Failed to create oidc object")
            return
        }

        let completionExpectation = expectation(description: "Completion should be called!")
        oidc.cancelBrowserSession {
            completionExpectation.fulfill()
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
