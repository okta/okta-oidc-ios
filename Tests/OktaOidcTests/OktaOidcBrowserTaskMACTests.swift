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

#if os(macOS)

class OktaOidcBrowserTaskMACPartialMock: OktaOidcBrowserTaskMAC {
    var downloadOidcConfigCalled = false

    override func downloadOidcConfiguration(callback: @escaping (OKTServiceConfiguration?, OktaOidcError?) -> Void) {
        downloadOidcConfigCalled = true
        let oidConfig = OKTServiceConfiguration(authorizationEndpoint: URL(string: "https://test.okta.com")!,
                                                tokenEndpoint: URL(string: "https://test.okta.com")!,
                                                issuer: URL(string: "https://test.okta.com")!,
                                                registrationEndpoint: URL(string: "https://test.okta.com")!,
                                                endSessionEndpoint: URL(string: "https://test.okta.com")!)
        callback(oidConfig, nil)
    }

    override func externalUserAgent() -> OKTExternalUserAgent? {
        let redirectURLString = self.redirectURL!.absoluteURL
        return OKTExternalUserAgentMacMock(with: URL(string: "\(redirectURLString)")!)
    }
}

class OktaOidcBrowserTaskMACTests: XCTestCase {

    func testInitMethod() {
        guard let config = createTestConfig() else {
            XCTFail("Failed to create test config")
            return
        }

        let redirectConfig = OktaRedirectServerConfiguration(successRedirectURL: URL(string: "https://test.okta.com"),
                                                             port: 63210,
                                                             domainName: "localhost")
        var browserTask = OktaOidcBrowserTaskMAC(config: config,
                                                 oktaAPI: OktaOidcApiMock(),
                                                 redirectServerConfiguration: redirectConfig)
        XCTAssertNotNil(browserTask.config)
        XCTAssertNotNil(browserTask.redirectServer)
        XCTAssertTrue(config === browserTask.config)
        XCTAssertEqual(browserTask.domainName, "localhost")
        XCTAssertNil(browserTask.redirectURL)

        browserTask = OktaOidcBrowserTaskMAC(config: config,
                                             oktaAPI: OktaOidcApiMock())
        XCTAssertNotNil(browserTask.config)
        XCTAssertNil(browserTask.redirectServer)
        XCTAssertTrue(config === browserTask.config)
        XCTAssertNil(browserTask.domainName)
        XCTAssertNil(browserTask.redirectURL)
    }

    func testSignInMethod() {
        guard let config = createTestConfig() else {
            XCTFail("Failed to create test config")
            return
        }
        var signInExpectation = expectation(description: "Completion should be called!")
        var browserTask = OktaOidcBrowserTaskMACPartialMock(config: config,
                                                            oktaAPI: OktaOidcApiMock(),
                                                            redirectServerConfiguration: OktaRedirectServerConfiguration.default)
        browserTask.signIn(validator: OKTDefaultTokenValidator()) { _, _ in
            XCTAssertTrue(browserTask.downloadOidcConfigCalled)
            signInExpectation.fulfill()
        }
        XCTAssertEqual(browserTask.redirectURL?.absoluteString, "http://127.0.0.1:63875/")
        waitForExpectations(timeout: 5.0, handler: nil)

        signInExpectation = expectation(description: "Completion should be called!")
        browserTask = OktaOidcBrowserTaskMACPartialMock(config: config,
                                                        oktaAPI: OktaOidcApiMock())
        browserTask.signIn(validator: OKTDefaultTokenValidator()) { _, _ in
            XCTAssertTrue(browserTask.downloadOidcConfigCalled)
            signInExpectation.fulfill()
        }
        XCTAssertEqual(browserTask.redirectURL?.absoluteString, "com.test:/callback")
        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testSignOutMethod() {
        guard let config = createTestConfig() else {
            XCTFail("Failed to create test config")
            return
        }
        var signInExpectation = expectation(description: "Completion should be called!")
        var browserTask = OktaOidcBrowserTaskMACPartialMock(config: config,
                                                            oktaAPI: OktaOidcApiMock(),
                                                            redirectServerConfiguration: OktaRedirectServerConfiguration.default)
        browserTask.signOutWithIdToken(idToken: "token") { _, _ in
            XCTAssertTrue(browserTask.downloadOidcConfigCalled)
            signInExpectation.fulfill()
        }
        XCTAssertEqual(browserTask.redirectURL?.absoluteString, "http://127.0.0.1:63875/")
        waitForExpectations(timeout: 5.0, handler: nil)

        signInExpectation = expectation(description: "Completion should be called!")
        browserTask = OktaOidcBrowserTaskMACPartialMock(config: config,
                                                        oktaAPI: OktaOidcApiMock())
        browserTask.signOutWithIdToken(idToken: "token") { _, _ in
            XCTAssertTrue(browserTask.downloadOidcConfigCalled)
            signInExpectation.fulfill()
        }
        XCTAssertEqual(browserTask.redirectURL?.absoluteString, "com.test:/logout")
        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testExternalUserAgentMethod() {
        guard let config = createTestConfig() else {
            XCTFail("Failed to create test config")
            return
        }
        let browserTask = OktaOidcBrowserTaskMAC(config: config,
                                                 oktaAPI: OktaOidcApiMock(),
                                                 redirectServerConfiguration: OktaRedirectServerConfiguration.default)
        let externalUserAgent = browserTask.externalUserAgent()
        XCTAssertNotNil(externalUserAgent)
        XCTAssertNotNil(externalUserAgent as? OKTExternalUserAgentMac)
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
