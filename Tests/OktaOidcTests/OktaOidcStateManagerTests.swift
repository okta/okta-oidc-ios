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

class OktaOidcStateManagerTests: XCTestCase {
    
    var apiMock: OktaOidcApiMock!
    var authStateManager: OktaOidcStateManager!

    override func setUp() {
        super.setUp()
        
        apiMock = OktaOidcApiMock()
        authStateManager = OktaOidcStateManager(
            authState: TestUtils.setupMockAuthState(issuer: TestUtils.mockIssuer, clientId: TestUtils.mockClientId)
        )
        
        authStateManager.restAPI = apiMock
    }

    override func tearDown() {
        apiMock = nil
        authStateManager = nil
        super.tearDown()
    }
    
    func testIntrospectSucceeded() {
        // Mock REST API calls
        apiMock.configure(response: ["active": true])
        
        let introspectExpectation = expectation(description: "Will succeed with payload.")
        
        authStateManager.introspect(token: authStateManager.accessToken) { payload, error in
            XCTAssertNil(error)
            XCTAssertEqual(true, payload?["active"] as? Bool)
            introspectExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testIntrospectNoBearerToken() {
        // Mock REST API calls
        apiMock.configure(response: ["active": true])
        
        let introspectExpectation = expectation(description: "Will succeed with payload.")
        
        authStateManager.introspect(token: nil) { payload, error in
            XCTAssertNil(payload)
            XCTAssertEqual(
                OktaOidcError.noBearerToken.localizedDescription,
                error?.localizedDescription
            )
            introspectExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testIntrospectFailed() {
        // Mock REST API calls
        let underlyingError = NSError(domain: NSURLErrorDomain,
                                      code: NSURLErrorNetworkConnectionLost,
                                      userInfo: [NSLocalizedDescriptionKey: "Localization error description"])
        let mockError = OktaOidcError.api(message: "Test Error", underlyingError: underlyingError)
        apiMock.configure(error: mockError)
        
        let introspectExpectation = expectation(description: "Will fail with error.")
        
        authStateManager.introspect(token: authStateManager.accessToken) { payload, error in
            XCTAssertNil(payload)
            
            XCTAssertEqual(mockError, error as? OktaOidcError)
            
            introspectExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testRevokeSucceeded() {
        // Mock REST API calls
        apiMock.configure(response: [:])
        
        let revokeExpectation = expectation(description: "Will succeed with payload.")
        
        authStateManager.revoke(authStateManager.accessToken) { isRevoked, error in
            XCTAssertTrue(isRevoked)
            XCTAssertNil(error)
            
            revokeExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }

    func testRevokeNoBearerToken() {
        // Mock REST API calls
        let underlyingError = NSError(domain: NSURLErrorDomain,
                                      code: NSURLErrorNetworkConnectionLost,
                                      userInfo: [NSLocalizedDescriptionKey: "Localization error description"])
        
        let mockError = OktaOidcError.api(message: "Test Error", underlyingError: underlyingError)
        apiMock.configure(error: mockError)
        
        let revokeExpectation = expectation(description: "Will fail with error.")
        
        authStateManager.revoke(nil) { isRevoked, error in
            XCTAssertFalse(isRevoked)
            
            XCTAssertEqual(OktaOidcError.noBearerToken, error as? OktaOidcError)
            
            revokeExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testRevokeFailed() {
        // Mock REST API calls
        let underlyingError = NSError(domain: NSURLErrorDomain,
                                      code: NSURLErrorNetworkConnectionLost,
                                      userInfo: [NSLocalizedDescriptionKey: "Localization error description"])
        
        let mockError = OktaOidcError.api(message: "Test Error", underlyingError: underlyingError)
        apiMock.configure(error: mockError)
        
        let revokeExpectation = expectation(description: "Will fail with error.")
        
        authStateManager.revoke(authStateManager.accessToken) { isRevoked, error in
            XCTAssertFalse(isRevoked)
            XCTAssertEqual(mockError, error as? OktaOidcError)
            
            revokeExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testGetUserSucceeded() {
        // Mock REST API calls
        apiMock.configure(response: ["username": "test"])
    
        let userInfoExpectation = expectation(description: "Will succeed with payload.")
    
        authStateManager.getUser { payload, error in
            XCTAssertEqual("test", payload?["username"] as? String)
            XCTAssertNil(error)
            
            userInfoExpectation.fulfill()
        }
    
        waitForExpectations(timeout: 5.0)
    }
    
    func testGetUserFailed() {
        // Mock REST API calls
        let underlyingError = NSError(domain: NSURLErrorDomain,
                                      code: NSURLErrorNetworkConnectionLost,
                                      userInfo: [NSLocalizedDescriptionKey: "Localization error description"])
        
        let mockError = OktaOidcError.api(message: "Test Error", underlyingError: underlyingError)
        apiMock.configure(error: mockError)
        
        let userInfoExpectation = expectation(description: "Will fail with error.")
        
        authStateManager.getUser { payload, error in
            XCTAssertNil(payload)
            XCTAssertEqual(mockError, error as? OktaOidcError)
            
            userInfoExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testGetUserFailedNoAccessToken() {
        // Mock REST API calls
        apiMock.configure(response: ["username": "test"])
        authStateManager.authState = TestUtils.setupMockAuthState(issuer: TestUtils.mockIssuer, clientId: TestUtils.mockClientId, skipTokenResponse: true)
        let userInfoExpectation = expectation(description: "Will fail with error.")
        
        authStateManager.getUser { payload, error in
            XCTAssertNil(payload)
            XCTAssertEqual(
                OktaOidcError.noBearerToken,
                error as? OktaOidcError
            )
            
            userInfoExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
    }
    
    func testIdTokenDecode() {
        // Expect that a provided token is parseable
        let idToken =
            "fakeHeader.eyJ2ZXIiOjEsImp0aSI6IkFULkNyNW55SFMtdTZwTjNaaDQ2cURJNTJBYmtCMkdoS3FzUEN" +
            "CN3NsdVplR2MuN1NwTms3Wk9HQ3pnL04zdlhuRXcybTdGNjdwMm5CTktoUnF0VEVpc0UxTT0iLCJpc3MiO" +
            "iJodHRwczovL2V4YW1wbGUuY29tIiwiYXVkIjoiYXBpOi8vZGVmYXVsdCIsImlhdCI6MTUxOTk2MDcxOSw" +
            "iZXhwIjoxNTE5OTcyNTA4LCJjaWQiOiJ7Y2xpZW50SWR9IiwidWlkIjoie3VpZH0iLCJzY3AiOlsib3Blb" +
            "mlkIiwib2ZmbGluZV9hY2Nlc3MiLCJwcm9maWxlIl0sInN1YiI6ImV4YW1wbGVAZXhhbXBsZS5jb20ifQ." +
            "fakeSignature"
        
        do {
            let response = try OktaOidcStateManager.decodeJWT(idToken)
            XCTAssertFalse(response.isEmpty)
        } catch let error {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testJWTFailedDecode() {
        let invalidIdToken = """
        eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.\
        InvalidJSON_eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.\
        SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
        """
        
        XCTAssertThrowsError(try OktaOidcStateManager.decodeJWT(invalidIdToken))
    }
    
    func testJWTEmptyDecode() {
        // Expect that a provided token is parseable
        let invalidIdToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9."
        
        XCTAssertTrue(try OktaOidcStateManager.decodeJWT(invalidIdToken).isEmpty)
    }
    
    func testTokenRefresh() {
        // given
        authStateManager.authState = OKTTokensAuthMock.makeDefault(shouldFailRefresh: false)
        
        let userInfoExpectation = expectation(description: "Will succeed to refresh token.")
        let oldRefreshToken = self.authStateManager.refreshToken
    
        // when
        authStateManager.renew { [unowned self] stateManager, error in
            // then
            XCTAssertNotNil(stateManager)
            XCTAssertTrue(stateManager! === self.authStateManager)
            XCTAssertEqual(self.authStateManager.refreshToken, self.authStateManager.authState.refreshToken)
            XCTAssertNotEqual(oldRefreshToken, self.authStateManager.authState.refreshToken)
            XCTAssertNil(error)
            
            userInfoExpectation.fulfill()
        }
    
        waitForExpectations(timeout: 5)
    }
    
    func testTokenRefreshFailed() {
        // given
        authStateManager.authState = OKTTokensAuthMock.makeDefault(shouldFailRefresh: true)
        
        let userInfoExpectation = expectation(description: "Will fail to refresh token.")
    
        // when
        authStateManager.renew { [unowned self] stateManager, error in
            // then
            XCTAssertNil(stateManager)
            XCTAssertNotNil(error)
            XCTAssertTrue(self.authStateManager.refreshToken == authStateManager.authState.refreshToken)

            if case OktaOidcError.errorFetchingFreshTokens = error! {
                userInfoExpectation.fulfill()
            } else {
                XCTFail("Refresh Token succeeded.")
            }
        }
    
        waitForExpectations(timeout: 5)
    }
    
    func testAccessToken() {
        // given
        authStateManager.authState = OKTTokensAuthMock.makeDefault(expiresIn: 5)
        // then
        XCTAssertNotNil(authStateManager.accessToken)
        XCTAssertEqual(authStateManager.accessToken, authStateManager.authState.lastTokenResponse?.accessToken)
    }
    
    func testExpiredAccessToken() {
        // given
        authStateManager.authState = OKTTokensAuthMock.makeDefault(expiresIn: 0.5)
        sleep(2)
        
        // then
        XCTAssertNil(authStateManager.accessToken)
        XCTAssertNotEqual(authStateManager.accessToken, authStateManager.authState.lastTokenResponse?.accessToken)
    }
    
    func testIdToken() {
        // given
        authStateManager.authState = OKTTokensAuthMock.makeDefault(expiredIDToken: false)
        // then
        XCTAssertNotNil(authStateManager.idToken)
        XCTAssertEqual(authStateManager.idToken, authStateManager.authState.lastTokenResponse?.idToken)
    }
    
    func testIdTokenFailed() {
        // given
        authStateManager.authState = OKTTokensAuthMock.makeDefault(expiredIDToken: true)
        // then
        XCTAssertNil(authStateManager.idToken)
        XCTAssertNotEqual(authStateManager.idToken, authStateManager.authState.lastTokenResponse?.idToken)
    }
    
    func testSetDelegate() {
        let authState = TestUtils.setupMockAuthState(issuer: TestUtils.mockIssuer, clientId: TestUtils.mockClientId, skipTokenResponse: true)
        let stateManager = OktaOidcStateManager(authState: authState)
        let delegateMock = OktaNetworkRequestCustomizationDelegateMock()
        stateManager.requestCustomizationDelegate = delegateMock
        XCTAssertEqual(stateManager.restAPI.requestCustomizationDelegate as? OktaNetworkRequestCustomizationDelegateMock, delegateMock)
        XCTAssertTrue(stateManager.authState.delegate === stateManager.restAPI.requestCustomizationDelegate)
    }

    #if !SWIFT_PACKAGE
    /// **Note:** Unit tests in Swift Package Manager do not support tests run from a host application, meaning some iOS features are unavailable.
    func testReadWriteToSecureStorage() {
        guard let testConfig1 = try? OktaOidcConfig(with: [
            "clientId": TestUtils.mockClientId,
            "issuer": TestUtils.mockIssuer,
            "scopes": "test",
            "redirectUri": "com.okta.sample:/test"
        ]) else {
            XCTFail("Unable to create test config")
            return
        }
        
        self.runTestReadWriteToSecureStorage(with: testConfig1)

        guard let testConfig2 = try? OktaOidcConfig(with: [
            "clientId": "0oa2p7eq7uDmZY4sJ0g70oa2p7eq7uDmZY4sJ0g7",
            "issuer": "https://long-long-long-long-long-long-url.trexcloud.com/oauth2/default",
            "scopes": "test",
            "redirectUri": "com.okta.sample:/test"
            ]) else {
                XCTFail("Unable to create test config")
                return
        }

        self.runTestReadWriteToSecureStorage(with: testConfig2)
    }

    func runTestReadWriteToSecureStorage(with config: OktaOidcConfig) {
        let manager = TestUtils.setupMockAuthStateManager(issuer: config.issuer, clientId: config.clientId, expiresIn: 5)
        
        XCTAssertNil(OktaOidcStateManager.readFromSecureStorage(for: config))
        
        manager.writeToSecureStorage()
        
        let storedManager = OktaOidcStateManager.readFromSecureStorage(for: config)
        XCTAssertNotNil(storedManager)
        XCTAssertEqual(
            storedManager?.authState.lastAuthorizationResponse.accessToken,
            manager.authState.lastAuthorizationResponse.accessToken
        )
        XCTAssertEqual(
            storedManager?.authState.lastAuthorizationResponse.idToken,
            manager.authState.lastAuthorizationResponse.idToken
        )

        XCTAssertNoThrow(try manager.removeFromSecureStorage())
        XCTAssertNil(OktaOidcStateManager.readFromSecureStorage(for: config))
    }
    #endif
}
