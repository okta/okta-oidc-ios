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
import XCTest

#if SWIFT_PACKAGE
@testable import TestCommon
#endif

#if os(iOS)

class OktaOidcPartialMock: OktaOidc {
    var originalBrowserTask: OktaOidcBrowserTask?
    
    override func signInWithBrowserTask(_ task: OktaOidcBrowserTask,
                                        callback: @escaping ((OktaOidcStateManager?, Error?) -> Void)) {
        originalBrowserTask = task
        DispatchQueue.main.async {
            let browserTaskIOS = task as! OktaOidcBrowserTaskIOS
            let task = OktaOidcBrowserTaskIOSMock(presenter: browserTaskIOS.presenter,
                                                  config: self.configuration,
                                                  oktaAPI: OktaOidcApiMock())
            super.signInWithBrowserTask(task, callback: callback)
        }
    }

    override func signOutWithBrowserTask(_ task: OktaOidcBrowserTask, idToken: String, callback: @escaping ((Error?) -> Void)) {
        originalBrowserTask = task
        DispatchQueue.main.async {
            let browserTaskIOS = task as! OktaOidcBrowserTaskIOS
            let task = OktaOidcBrowserTaskIOSMock(presenter: browserTaskIOS.presenter,
                                                  config: self.configuration,
                                                  oktaAPI: OktaOidcApiMock())
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
        oidc.signInWithBrowser(from: UIViewController()) { stateManager, error in
            XCTAssertNotNil(stateManager)
            XCTAssertNotNil(stateManager?.accessToken)
            XCTAssertNotNil(stateManager?.refreshToken)
            XCTAssertNil(error)
            signInExpectation.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testSignInSuccessFlowWithAdditionalParams() {
        guard let oidc = try? OktaOidcPartialMock(configuration: createTestConfig()) else {
            XCTFail("Failed to create oidc object")
            return
        }
        
        let signInExpectation = expectation(description: "Completion should be called!")
        oidc.signInWithBrowser(from: UIViewController(), additionalParameters: ["additional": "param"]) { stateManager, error in
            XCTAssertNotNil(stateManager)
            XCTAssertNotNil(stateManager?.accessToken)
            XCTAssertNotNil(stateManager?.refreshToken)
            XCTAssertNil(error)
            signInExpectation.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
        
        XCTAssertEqual(oidc.originalBrowserTask?.config.additionalParams, ["additional": "param"])
    }

    func testSignInFailureFlow() {
        guard let oidc = try? OktaOidc(configuration: createTestConfig()) else {
            XCTFail("Failed to create oidc object")
            return
        }

        let signInExpectation = expectation(description: "Completion should be called!")
        oidc.signInWithBrowser(from: UIViewController()) { stateManager, error in
            XCTAssertNil(stateManager)
            XCTAssertNotNil(error)
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
        oidc.signOutOfOkta(authStateManager, from: UIViewController()) { error in
            XCTAssertNil(error)
            signOutExpectation.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testSignOutFailureFlow() {
        guard let oidc = try? OktaOidc(configuration: createTestConfig()) else {
            XCTFail("Failed to create oidc object")
            return
        }

        let signOutExpectation = expectation(description: "Completion should be called!")
        let authStateManager = OktaOidcStateManager(
            authState: TestUtils.setupMockAuthState(issuer: TestUtils.mockIssuer, clientId: TestUtils.mockClientId)
        )
        oidc.signOutOfOkta(authStateManager, from: UIViewController()) { error in
            XCTAssertNotNil(error)
            signOutExpectation.fulfill()
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
