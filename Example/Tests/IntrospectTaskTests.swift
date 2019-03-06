import XCTest
@testable import OktaAuth

class IntrospectTaskTests: XCTestCase {

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
        
        apiMock.configure(response: ["active": true])
        
        runAndWaitIntrospect(config: config, token: "test_token") { isValid, error in
            XCTAssertNil(error)
            XCTAssertEqual(true, isValid)
        }
    }

    func testRunNotConfigured() {
        apiMock.configure(response: [:]) { request in
            XCTFail("Should not make a request to API!")
        }
        
        runAndWaitIntrospect(config: nil, token: "test_token") { isValid, error in
            XCTAssertNil(isValid)
            XCTAssertEqual(
                OktaError.notConfigured.localizedDescription,
                error?.localizedDescription
            )
        }
    }
    
    func testRunNoIntrospectionEndpoint() {
        // value for "issuer" missing
        let config = OktaAuthConfig(with: ["clientId" : "test_client_id"])
        
        apiMock.configure(response: [:]) { request in
            XCTFail("Should not make a request to API!")
        }
        
        runAndWaitIntrospect(config: config, token: "test_token") { isValid, error in
            XCTAssertNil(isValid)
            XCTAssertEqual(
                OktaError.noIntrospectionEndpoint.localizedDescription,
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
        
        runAndWaitIntrospect(config: config, token: nil) { isValid, error in
            XCTAssertNil(isValid)
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
        
        runAndWaitIntrospect(config: config, token: "test_token") { isValid, error in
            XCTAssertNil(isValid)
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
        
        runAndWaitIntrospect(config: config, token: "test_token") { isValid, error in
            XCTAssertNil(isValid)
            XCTAssertEqual(
                OktaError.APIError("Test Error").localizedDescription,
                error?.localizedDescription
            )
        }
    }
    
    func testRunParseError() {
        let config = OktaAuthConfig(with: [
            "clientId" : "test_client_id",
            "issuer" : "http://test.issuer.com/oauth2/default"
        ])
        
        apiMock.configure(response: ["invalidKey" : ""])
        
        runAndWaitIntrospect(config: config, token: "test_token") { oidConfig, error in
            XCTAssertNil(oidConfig)
            XCTAssertEqual(
                OktaError.parseFailure.localizedDescription,
                error?.localizedDescription
            )
        }
    }
    
    func testRunIntrospectionEndpointURL() {
        let config = OktaAuthConfig(with: [
            "clientId" : "test_client_id",
            "issuer" : "http://test.issuer.com/"
        ])
        
        apiMock.configure(response: ["active": true]) { request in
            XCTAssertEqual(
                "http://test.issuer.com/oauth2/v1/introspect",
                request.url?.absoluteString
            )
        }
        
        runAndWaitIntrospect(config: config, token: "test_token") { isValid, error in
            XCTAssertNil(error)
            XCTAssertEqual(true, isValid)
        }
    }
    
    func testRunIntrospectionEndpointURLWithOAth2() {
        let config = OktaAuthConfig(with: [
            "clientId" : "test_client_id",
            "issuer" : "http://test.issuer.com/oauth2/default"
        ])
        
        apiMock.configure(response: ["active": true]) { request in
            XCTAssertEqual(
                "http://test.issuer.com/oauth2/default/v1/introspect",
                request.url?.absoluteString
            )
        }
        
        runAndWaitIntrospect(config: config, token: "test_token") { isValid, error in
            XCTAssertNil(error)
            XCTAssertEqual(true, isValid)
        }
    }
    
    // MARK: - Utils
    
    private func runAndWaitIntrospect(config: OktaAuthConfig?,
                                      token: String?,
                                      validationHandler: @escaping (Bool?, OktaError?) -> Void) {
        let ex = expectation(description: "Introspect should be called!")
        IntrospectTask(config: config, token: token).run { isValid, error in
            validationHandler(isValid, error)
            ex.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }
}
