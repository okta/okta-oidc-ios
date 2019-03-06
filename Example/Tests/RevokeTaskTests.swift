import XCTest
@testable import OktaAuth

class RevokeTaskTests: XCTestCase {

    var apiMock: OktaApiMock!
    
    override func setUp() {
        super.setUp()
        apiMock = OktaApiMock()
        apiMock.installMock()
    }

    override func tearDown() {
        OktaApiMock.resetMock()
        super.tearDown()
    }
    
    func testRunSucceeded() {
        let config = OktaAuthConfig(with: [
            "clientId" : "test_client_id",
            "issuer" : "http://test.issuer.com/oauth2/default"
        ])
        
        apiMock.configure(response: [:])
        
        runAndWaitRevoke(config: config, token: "test_token") { isRevoked, error in
            XCTAssertNil(error)
            XCTAssertEqual(true, isRevoked)
        }
    }

    func testRunNotConfigured() {
        apiMock.configure(response: [:]) { request in
            XCTFail("Should not make a request to API!")
        }
        
        runAndWaitRevoke(config: nil, token: "test_token") { isRevoked, error in
            XCTAssertNil(isRevoked)
            XCTAssertEqual(
                OktaError.notConfigured.localizedDescription,
                error?.localizedDescription
            )
        }
    }
    
    func testRunNoRevocationEndpoint() {
        // value for "issuer" missing
        let config = OktaAuthConfig(with: ["clientId" : "test_client_id"])
        
        apiMock.configure(response: [:]) { request in
            XCTFail("Should not make a request to API!")
        }
        
        runAndWaitRevoke(config: config, token: "test_token") { isRevoked, error in
            XCTAssertNil(isRevoked)
            XCTAssertEqual(
                OktaError.noRevocationEndpoint.localizedDescription,
                error?.localizedDescription
            )
        }
    }
    
    func testRunNoBearerToken() {
        // value for "clientId" missing
        let config = OktaAuthConfig(with: ["issuer" : "http://test.issuer.com/oauth2/default"])
        
        apiMock.configure(response: [:]) { request in
            XCTFail("Should not make a request to API!")
        }
        
        runAndWaitRevoke(config: config, token: nil) { isRevoked, error in
            XCTAssertNil(isRevoked)
            XCTAssertEqual(
                OktaError.noBearerToken.localizedDescription,
                error?.localizedDescription
            )
        }
    }
    
    func testRunMissingConfigurationValues() {
        // value for "clientId" missing
        let config = OktaAuthConfig(with: ["issuer" : "http://test.issuer.com/oauth2/default"])
        
        apiMock.configure(response: [:]) { request in
            XCTFail("Should not make a request to API!")
        }
        
        runAndWaitRevoke(config: config, token: "test_token") { isRevoked, error in
            XCTAssertNil(isRevoked)
            XCTAssertEqual(
                OktaError.missingConfigurationValues.localizedDescription,
                error?.localizedDescription
            )
        }
    }
    
    func testRunApiError() {
        let config = OktaAuthConfig(with: [
            "clientId" : "test_client_id",
            "issuer" : "http://test.issuer.com/oauth2/default"
        ])
        
        apiMock.configure(error: OktaError.APIError("Test Error"))
        
        runAndWaitRevoke(config: config, token: "test_token") { isRevoked, error in
            XCTAssertNil(isRevoked)
            XCTAssertEqual(
                OktaError.APIError("Test Error").localizedDescription,
                error?.localizedDescription
            )
        }
    }
    
    func testRunRevokationEndpointURL() {
        let config = OktaAuthConfig(with: [
            "clientId" : "test_client_id",
            "issuer" : "http://test.issuer.com/"
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
        let config = OktaAuthConfig(with: [
            "clientId" : "test_client_id",
            "issuer" : "http://test.issuer.com/oauth2/default"
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
    
    private func runAndWaitRevoke(config: OktaAuthConfig?,
                                  token: String?,
                                  validationHandler: @escaping (Bool?, OktaError?) -> Void) {
        let ex = expectation(description: "Revoke should be called!")
        RevokeTask(config: config, token: token).run { isRevoked, error in
            validationHandler(isRevoked, error)
            ex.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }
}
