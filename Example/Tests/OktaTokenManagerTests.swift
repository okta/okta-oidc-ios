import XCTest
@testable import OktaAuth

class OktaTokenManagerTests: XCTestCase {
    
    var apiMock: OktaApiMock!
    var tokensManager: OktaTokenManager!

    override func setUp() {
        super.setUp()
        OktaAuth.configuration = try? OktaAuthConfig(with:[
            "issuer" : "http://test.issuer.com/oauth2/default",
            "clientId" : "test_client",
            "scopes" : "test",
            "redirectUri" : "test:/callback"
        ])
        
        apiMock = OktaApiMock()
        tokensManager = OktaTokenManager(
            authState: TestUtils.setupMockAuthState(issuer: TestUtils.mockIssuer)
        )
        
        tokensManager.restAPI = apiMock
    }

    override func tearDown() {
        OktaAuth.configuration = try? OktaAuthConfig.default()
        apiMock = nil
        tokensManager = nil
        super.tearDown()
    }
    
    func testIntrospectSucceeded() {
        // Mock REST API calls
        apiMock.configure(response: ["active" : true])
        
        let introspectExpectation = expectation(description: "Will succeed with payload.")
        
        tokensManager.introspect(token: tokensManager.accessToken) { payload, error in
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
        
        tokensManager.introspect(token: nil) { payload, error in
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
        
        tokensManager.introspect(token: tokensManager.accessToken) { payload, error in
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
        
        tokensManager.revoke(tokensManager.accessToken){ isRevoked, error in
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
        
        tokensManager.revoke(nil){ isRevoked, error in
            XCTAssertNil(isRevoked)
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
        
        tokensManager.revoke(tokensManager.accessToken){ isRevoked, error in
            XCTAssertNil(isRevoked)
            XCTAssertEqual(
                OktaError.APIError("Test Error").localizedDescription,
                error?.localizedDescription
            )
            
            revokeExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
}
