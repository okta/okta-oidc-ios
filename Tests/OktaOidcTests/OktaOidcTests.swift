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

// swiftlint:disable force_try
// swiftlint:disable force_cast
// swiftlint:disable force_unwrapping

@testable import OktaOidc
import XCTest

#if SWIFT_PACKAGE
@testable import TestCommon
#endif

class OktaOidcTests: XCTestCase {

    private let issuer = ProcessInfo.processInfo.environment["ISSUER"]
    private let clientId = ProcessInfo.processInfo.environment["CLIENT_ID"]
    private let redirectUri = ProcessInfo.processInfo.environment["REDIRECT_URI"]
    private let logoutRedirectUri = ProcessInfo.processInfo.environment["LOGOUT_REDIRECT_URI"]
    
    private var envConfig: OktaOidcConfig? {
        guard issuer != nil &&
                clientId != nil &&
                redirectUri != nil &&
                logoutRedirectUri != nil
        else {
            return nil
        }
        
        return try? OktaOidcConfig(with: [
            "issuer": issuer!,
            "clientId": clientId!,
            "redirectUri": redirectUri!,
            "logoutRedirectUri": logoutRedirectUri!,
            "scopes": "openid profile offline_access"
        ])
    }

    var apiMock: OktaOidcApiMock!
    var authStateManager: OktaOidcStateManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        continueAfterFailure = false
        
        try XCTSkipIf(issuer == nil || clientId == nil || redirectUri == nil || logoutRedirectUri == nil,
                      "OAuth app settings not configured")
        
        apiMock = OktaOidcApiMock()
        authStateManager = OktaOidcStateManager(
            authState: TestUtils.setupMockAuthState(issuer: TestUtils.mockIssuer, clientId: TestUtils.mockClientId)
        )

        authStateManager.restAPI = apiMock
    }
    
    #if os(iOS) && !SWIFT_PACKAGE
    /// **Note:** Tests run in Swift Package Manager do not have access to a common application host, so the Okta.plist file is not accessible.
    func testCreationWithNil() {
        // Depends on whether Okta.plist is configured or not
        if let defaultConfig = try? OktaOidcConfig.default() {
            let oktaOidc = try? OktaOidc()
            XCTAssertNotNil(oktaOidc)
            XCTAssertEqual(defaultConfig, oktaOidc?.configuration)
        } else {
            XCTAssertThrowsError(try OktaOidc()) { error in
                XCTAssertEqual(
                    OktaOidcError.missingConfigurationValues.localizedDescription,
                    error.localizedDescription
                )
            }
        }
    }
    #endif
    
    func testCreationWithEnvConfig() {
        guard let envConfig = envConfig else {
            XCTFail("Please, configure environment variables to create config!")
            return
        }

        let oktaOidc = try? OktaOidc(configuration: envConfig)
        XCTAssertNotNil(oktaOidc)
    }

    func testSignOutOptions() {
        var options: OktaSignOutOptions = []
        options.insert(.allOptions)
        XCTAssertTrue(options.contains(.revokeAccessToken))
        XCTAssertTrue(options.contains(.revokeRefreshToken))
        XCTAssertTrue(options.contains(.signOutFromOkta))
        XCTAssertTrue(options.contains(.removeTokensFromStorage))

        options.remove(.allOptions)
        options.insert(.revokeTokensOptions)
        XCTAssertTrue(options.contains(.revokeAccessToken))
        XCTAssertTrue(options.contains(.revokeRefreshToken))
        XCTAssertFalse(options.contains(.signOutFromOkta))
        XCTAssertFalse(options.contains(.removeTokensFromStorage))
    }

    func createDummyConfig() -> OktaOidcConfig? {
        return try? OktaOidcConfig(with: ["issuer": TestUtils.mockIssuer, "clientId": TestUtils.mockClientId, "scopes": "id_token", "redirectUri": "com.example:/callback"])
    }

    func createDummyOidcObject() -> OktaOidc? {
        let dummyConfig = createDummyConfig()
        let oktaOidc = try? OktaOidc(configuration: dummyConfig)
        XCTAssertNotNil(oktaOidc)
        return oktaOidc
    }
}

#if os(iOS)
extension OktaOidcTests {
    
    func testSignOutWithEmptyOptions() {
        let oktaOidc = createDummyOidcObject()
        let viewController = UIViewController(nibName: nil, bundle: nil)
        oktaOidc?.signOut(with: [], authStateManager: authStateManager, from: viewController, progressHandler: { _ in
            XCTFail("Unexpected progress step")
        },
        completionHandler: { result, failedOptions in
            XCTAssertTrue(result)
            XCTAssertTrue(failedOptions.isEmpty)
        })
    }
    
    func testSignOutWithoutRefreshToken() throws {
        // given
        let oktaOidc = createDummyOidcObject()
        authStateManager.authState = TestUtils.setupMockAuthState(issuer: TestUtils.mockIssuer, clientId: TestUtils.mockClientId, refreshToken: "", skipTokenResponse: false)
        
        var numberOfRevokes = 0
        apiMock.configure(response: [:]) { urlRequest in
            let url = urlRequest.url!
            XCTAssertTrue(url.absoluteString.contains("/oauth2/default/v1/revoke"), "Wrong endpoint has been called")
            numberOfRevokes += 1
        }
        
        let viewController = UIViewController(nibName: nil, bundle: nil)
        let options: OktaSignOutOptions = .revokeTokensOptions
        var currentStep = 1
        
        // when
        oktaOidc?.signOut(with: options, authStateManager: authStateManager, from: viewController, progressHandler: { currentOption in
            XCTAssertFalse(currentStep == 1 && !currentOption.contains(.revokeAccessToken), "Expected revoke acces token step")
            XCTAssertFalse(currentStep == 2 && !currentOption.contains(.revokeRefreshToken), "Expected revoke refresh token step")
            XCTAssertFalse(currentOption.contains(.removeTokensFromStorage) || currentOption.contains(.signOutFromOkta), "Unexpected progress step")
            
            currentStep += 1
        },
        completionHandler: { result, failedOptions in
            // then
            XCTAssertEqual(currentStep, 3)
            XCTAssertEqual(numberOfRevokes, 1)
            XCTAssertTrue(result)
            XCTAssertTrue(failedOptions.isEmpty)
        })
    }

    func testSignOutWithTokensOptions() {
        let oktaOidc = createDummyOidcObject()
        var numberOfRevokes = 0
        apiMock.configure(response: [:]) { urlRequest in
            if let url = urlRequest.url, url.absoluteString.contains("/oauth2/default/v1/revoke") {
                numberOfRevokes = numberOfRevokes + 1
            } else {
                XCTFail("Wrong endpoint has been called")
            }
        }
        let viewController = UIViewController(nibName: nil, bundle: nil)
        let options: OktaSignOutOptions = .revokeTokensOptions
        var currentStep = 1
        oktaOidc?.signOut(with: options, authStateManager: authStateManager, from: viewController, progressHandler: { currentOption in
            if currentStep == 1 && !currentOption.contains(.revokeAccessToken) {
                XCTFail("Expected revoke acces token step")
            } else if currentStep == 2 && !currentOption.contains(.revokeRefreshToken) {
                XCTFail("Expected revoke refresh token step")
            } else if currentOption.contains(.removeTokensFromStorage) || currentOption.contains(.signOutFromOkta) {
                XCTFail("Unexpected progress step")
            }
            currentStep = currentStep + 1
        },
        completionHandler: { result, failedOptions in
            XCTAssertEqual(numberOfRevokes, 2)
            XCTAssertTrue(result)
            XCTAssertTrue(failedOptions.isEmpty)
        })
    }
        
    func testSignOutWithTokensAndRemoveFromStorageOptions() {
        let oktaOidc = createDummyOidcObject()
        var numberOfRevokes = 0
        apiMock.configure(response: [:]) { urlRequest in
            if let url = urlRequest.url, url.absoluteString.contains("/oauth2/default/v1/revoke") {
                numberOfRevokes = numberOfRevokes + 1
            } else {
                XCTFail("Wrong endpoint has been called")
            }
        }
        let viewController = UIViewController(nibName: nil, bundle: nil)
        let options: OktaSignOutOptions = [.revokeAccessToken, .revokeRefreshToken, .removeTokensFromStorage]
        authStateManager.writeToSecureStorage()
        guard OktaOidcStateManager.readFromSecureStorage(for: createDummyConfig()!) != nil else {
            XCTFail("Failed to read from secure storage")
            return
        }
        
        let expectation = self.expectation(description: "Revoke and remove tokens should be called")
        var currentStep = 1
        oktaOidc?.signOut(with: options, authStateManager: authStateManager, from: viewController, progressHandler: { currentOption in
            if currentStep == 1 && !currentOption.contains(.revokeAccessToken) {
                XCTFail("Expected revoke acces token step")
            } else if currentStep == 2 && !currentOption.contains(.revokeRefreshToken) {
                XCTFail("Expected revoke refresh token step")
            } else if currentStep == 3 && !currentOption.contains(.removeTokensFromStorage) {
                XCTFail("Expected remove tokens step")
            } else if currentOption.contains(.signOutFromOkta) {
                XCTFail("Unexpected progress step")
            }
            currentStep = currentStep + 1
        },
        completionHandler: { result, failedOptions in
            XCTAssertEqual(numberOfRevokes, 2)
            XCTAssertTrue(result)
            XCTAssertTrue(failedOptions.isEmpty)
            if OktaOidcStateManager.readFromSecureStorage(for: self.createDummyConfig()!) != nil {
                XCTFail("Data has not been deleted from the secure storage")
            }
            expectation.fulfill()
        })
        
        self.wait(for: [expectation], timeout: 1)
    }

    func testSignOutWithTokensOptions_failRevokeAccessToken() {
        let oktaOidc = createDummyOidcObject()
        var numberOfRevokes = 0
        apiMock.configure(error: .noRefreshToken) { urlRequest in
            if let url = urlRequest.url, url.absoluteString.contains("/oauth2/default/v1/revoke") {
                numberOfRevokes = numberOfRevokes + 1
            } else {
                XCTFail("Wrong endpoint has been called")
            }
        }
        let viewController = UIViewController(nibName: nil, bundle: nil)
        let options: OktaSignOutOptions = [.revokeAccessToken]
        let expectation = self.expectation(description: "Revoke should be called only for access token")
        var currentStep = 1
        oktaOidc?.signOut(with: options, authStateManager: authStateManager, from: viewController, progressHandler: { currentOption in
            if currentStep == 1 && !currentOption.contains(.revokeAccessToken) {
                XCTFail("Expected revoke acces token step")
            } else if currentOption.contains(.revokeRefreshToken)       ||
                      currentOption.contains(.removeTokensFromStorage)  ||
                      currentOption.contains(.signOutFromOkta) {
                XCTFail("Unexpected progress step")
            }
            currentStep = currentStep + 1
        },
        completionHandler: { result, failedOptions in
            XCTAssertEqual(numberOfRevokes, 1)
            XCTAssertFalse(result)
            XCTAssertTrue(failedOptions.contains(.revokeAccessToken))
            expectation.fulfill()
        })
        
        self.wait(for: [expectation], timeout: 1)
    }

    func testSignOutWithTokensOptions_failRevokeRefreshToken() {
        let oktaOidc = createDummyOidcObject()
        var numberOfRevokes = 0
        apiMock.configure(response: [:]) { urlRequest in
            if let url = urlRequest.url, url.absoluteString.contains("/oauth2/default/v1/revoke") {
                numberOfRevokes = numberOfRevokes + 1
                self.apiMock.configure(error: .noRefreshToken) { urlRequest in
                    if let url = urlRequest.url, url.absoluteString.contains("/oauth2/default/v1/revoke") {
                        numberOfRevokes = numberOfRevokes + 1
                    } else {
                        XCTFail("Wrong endpoint has been called")
                    }
                }
            } else {
                XCTFail("Wrong endpoint has been called")
            }
        }
        let viewController = UIViewController(nibName: nil, bundle: nil)
        let options: OktaSignOutOptions = [.revokeAccessToken, .revokeRefreshToken, .removeTokensFromStorage]
        let expectation = self.expectation(description: "Revoke should be called for both tokens")
        var currentStep = 1
        oktaOidc?.signOut(with: options, authStateManager: authStateManager, from: viewController, progressHandler: { currentOption in
            if currentStep == 1 && !currentOption.contains(.revokeAccessToken) {
                XCTFail("Expected revoke acces token step")
            } else if currentStep == 2 && !currentOption.contains(.revokeRefreshToken) {
                XCTFail("Expected revoke refresh token step")
            } else if currentOption.contains(.removeTokensFromStorage) || currentOption.contains(.signOutFromOkta) {
                XCTFail("Unexpected progress step")
            }
            currentStep = currentStep + 1
        },
        completionHandler: { result, failedOptions in
            XCTAssertEqual(numberOfRevokes, 2)
            XCTAssertFalse(result)
            XCTAssertTrue(failedOptions.contains(.revokeRefreshToken))
            XCTAssertFalse(failedOptions.contains(.revokeAccessToken))
            expectation.fulfill()
        })
        
        self.wait(for: [expectation], timeout: 5)
    }

}
#endif
