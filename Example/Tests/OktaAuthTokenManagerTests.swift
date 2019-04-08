import XCTest
@testable import OktaAuth

class OktaAuthTokenManagerTests: XCTestCase {
    
    var apiMock: OktaApiMock!
    var authStateManager: OktaAuthStateManager!

    override func setUp() {
        super.setUp()
        apiMock = OktaApiMock()
        authStateManager = OktaAuthStateManager(
            authState: TestUtils.setupMockAuthState(issuer: TestUtils.mockIssuer)
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
                OktaError.noBearerToken.localizedDescription,
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
                OktaError.APIError("Test Error").localizedDescription,
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
                OktaError.noBearerToken.localizedDescription,
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
                OktaError.APIError("Test Error").localizedDescription,
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
                OktaError.APIError("Test Error").localizedDescription,
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
            let response = try OktaAuthStateManager.decodeJWT(idToken)
            XCTAssertNotNil(response)
        } catch let error {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testReadWriteToSecureStorage() {
        guard let testConfig = try? OktaAuthConfig(with: [
            "clientId" : TestUtils.mockClientId,
            "issuer" : TestUtils.mockIssuer,
            "scopes" : "test",
            "redirectUri" : "http://test"
        ]) else {
            XCTFail("Unable to create test config")
            return
        }
        
        let manager = TestUtils.authStateManager()
        
        XCTAssertNil(OktaAuthStateManager.readFromSecureStorage(for: testConfig))
        
        manager.writeToSecureStorage()
        
        let storedManager = OktaAuthStateManager.readFromSecureStorage(for: testConfig)
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
        XCTAssertNil(OktaAuthStateManager.readFromSecureStorage(for: testConfig))
    }
}
