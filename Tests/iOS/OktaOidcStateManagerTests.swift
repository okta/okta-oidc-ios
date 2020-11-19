/*
 * Copyright (c) 2019, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import XCTest
@testable import OktaOidc

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
        apiMock.configure(response: ["active" : true])
        
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
        apiMock.configure(response: ["active" : true])
        
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
        apiMock.configure(error: .APIError("Test Error"))
        
        let introspectExpectation = expectation(description: "Will fail with error.")
        
        authStateManager.introspect(token: authStateManager.accessToken) { payload, error in
            XCTAssertNil(payload)
            XCTAssertEqual(
                OktaOidcError.APIError("Test Error").localizedDescription,
                error?.localizedDescription
            )
            introspectExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testRevokeSucceeded() {
        // Mock REST API calls
        apiMock.configure(response: [:])
        
        let revokeExpectation = expectation(description: "Will succeed with payload.")
        
        authStateManager.revoke(authStateManager.accessToken){ isRevoked, error in
            XCTAssertEqual(true, isRevoked)
            XCTAssertNil(error)
            
            revokeExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }

    func testRevokeNoBearerToken() {
        // Mock REST API calls
        apiMock.configure(error: .APIError("Test Error"))
        
        let revokeExpectation = expectation(description: "Will fail with error.")
        
        authStateManager.revoke(nil){ isRevoked, error in
            XCTAssertFalse(isRevoked)
            XCTAssertEqual(
                OktaOidcError.noBearerToken.localizedDescription,
                error?.localizedDescription
            )
            
            revokeExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testRevokeFailed() {
        // Mock REST API calls
        apiMock.configure(error: .APIError("Test Error"))
        
        let revokeExpectation = expectation(description: "Will fail with error.")
        
        authStateManager.revoke(authStateManager.accessToken){ isRevoked, error in
            XCTAssertFalse(isRevoked)
            XCTAssertEqual(
                OktaOidcError.APIError("Test Error").localizedDescription,
                error?.localizedDescription
            )
            
            revokeExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testGetUserSucceeded() {
        // Mock REST API calls
        apiMock.configure(response: ["username" : "test"])
    
        let userInfoExpectation = expectation(description: "Will succeed with payload.")
    
        authStateManager.getUser() { payload, error in
            XCTAssertEqual("test", payload?["username"] as? String)
            XCTAssertNil(error)
            
            userInfoExpectation.fulfill()
        }
    
        waitForExpectations(timeout: 5.0)
    }
    
    func testGetUserFailed() {
        // Mock REST API calls
        apiMock.configure(error: .APIError("Test Error"))
        
        let userInfoExpectation = expectation(description: "Will fail with error.")
        
        authStateManager.getUser(){ payload, error in
            XCTAssertNil(payload)
            XCTAssertEqual(
                OktaOidcError.APIError("Test Error").localizedDescription,
                error?.localizedDescription
            )
            
            userInfoExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
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
            XCTAssertNotNil(response)
        } catch let error {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testReadWriteToSecureStorage() {
        guard let testConfig1 = try? OktaOidcConfig(with: [
            "clientId" : TestUtils.mockClientId,
            "issuer" : TestUtils.mockIssuer,
            "scopes" : "test",
            "redirectUri" : "http://test"
        ]) else {
            XCTFail("Unable to create test config")
            return
        }
        
        self.runTestReadWriteToSecureStorage(with: testConfig1)

        guard let testConfig2 = try? OktaOidcConfig(with: [
            "clientId" : "0oa2p7eq7uDmZY4sJ0g70oa2p7eq7uDmZY4sJ0g7",
            "issuer" : "https://long-long-long-long-long-long-url.trexcloud.com/oauth2/default",
            "scopes" : "test",
            "redirectUri" : "http://test"
            ]) else {
                XCTFail("Unable to create test config")
                return
        }

        self.runTestReadWriteToSecureStorage(with: testConfig2)
    }

    func runTestReadWriteToSecureStorage(with config: OktaOidcConfig) {
        let manager = TestUtils.setupMockAuthStateManager(issuer: config.issuer, clientId: config.clientId,  expiresIn: 5)
        
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
        
        manager.clear()
        XCTAssertNil(OktaOidcStateManager.readFromSecureStorage(for: config))
    }
}
