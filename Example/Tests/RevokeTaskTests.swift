import XCTest
@testable import OktaAuth

class RevokeTaskTests: XCTestCase {

    var apiMock: OktaApiMock!
    
    override func setUp() {
        super.setUp()
        apiMock = OktaApiMock()
    }

    override func tearDown() {
        apiMock = nil
        super.tearDown()
    }
    
    func testRunSucceeded() {
        apiMock.configure(response: [:])
        
        runAndWaitRevoke(config: validConfig, token: "test_token") { isRevoked, error in
            XCTAssertNil(error)
            XCTAssertEqual(true, isRevoked)
        }
    }
    
    func testRunNoBearerToken() {
        apiMock.configure(response: [:]) { request in
            XCTFail("Should not make a request to API!")
        }
        
        runAndWaitRevoke(config: validConfig, token: nil) { isRevoked, error in
            XCTAssertNil(isRevoked)
            XCTAssertEqual(
                OktaError.noBearerToken.localizedDescription,
                error?.localizedDescription
            )
        }
    }
    
    func testRunApiError() {
        apiMock.configure(error: OktaError.APIError("Test Error"))
        
        runAndWaitRevoke(config: validConfig, token: "test_token") { isRevoked, error in
            XCTAssertNil(isRevoked)
            XCTAssertEqual(
                OktaError.APIError("Test Error").localizedDescription,
                error?.localizedDescription
            )
        }
    }
    
    func testRunRevokationEndpointURL() {
        let config = try! OktaAuthConfig(with: [
            "clientId" : "test_client_id",
            "issuer" : "http://test.issuer.com/",
            "scopes" : "test",
            "redirectUri" : "test:/callback"
        ])
        
        apiMock.configure(response: [:]) { request in
            XCTAssertEqual(
                "http://test.issuer.com/oauth2/v1/revoke",
                request.url?.absoluteString
            )
        }
        
        runAndWaitRevoke(config: config, token: "test_token") { isRevoked, error in
            XCTAssertNil(error)
            XCTAssertEqual(true, isRevoked)
        }
    }
    
    func testRunRevokationEndpointURLWithOAth2() {
        let config = try! OktaAuthConfig(with: [
            "clientId" : "test_client_id",
            "issuer" : "http://test.issuer.com/oauth2/default",
            "scopes" : "test",
            "redirectUri" : "test:/callback"
        ])
        
        apiMock.configure(response: [:]) { request in
            XCTAssertEqual(
                "http://test.issuer.com/oauth2/default/v1/revoke",
                request.url?.absoluteString
            )
        }
        
        runAndWaitRevoke(config: config, token: "test_token") { isRevoked, error in
            XCTAssertNil(error)
            XCTAssertEqual(true, isRevoked)
        }
    }
    
    // MARK: - Utils
    
    private func runAndWaitRevoke(config: OktaAuthConfig,
                                  token: String?,
                                  validationHandler: @escaping (Bool?, OktaError?) -> Void) {
        let ex = expectation(description: "Revoke should be called!")
        RevokeTask(token: token, config: config, oktaAPI: apiMock).run { isRevoked, error in
            validationHandler(isRevoked, error)
            ex.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    private var validConfig: OktaAuthConfig {
        return try! OktaAuthConfig(with: [
            "issuer" : "http://test.issuer.com/oauth2/default",
            "clientId" : "test_client",
            "scopes" : "test",
            "redirectUri" : "test:/callback"
        ])
    }
}
