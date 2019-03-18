import XCTest
@testable import OktaAuth

class IntrospectTaskTests: XCTestCase {

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
        apiMock.configure(response: ["active": true])
        
        runAndWaitIntrospect(config: validConfig, token: "test_token") { payload, error in
            XCTAssertNil(error)
            XCTAssertEqual(true, payload?["active"] as? Bool)
        }
    }
    
    func testRunNoBearerToken() {
        apiMock.configure(response: [:]) { request in
            XCTFail("Should not make a request to API!")
        }
        
        runAndWaitIntrospect(config: validConfig, token: nil) { isValid, error in
            XCTAssertNil(isValid)
            XCTAssertEqual(
                OktaError.noBearerToken.localizedDescription,
                error?.localizedDescription
            )
        }
    }
    
    func testRunApiError() {
        apiMock.configure(error: OktaError.APIError("Test Error"))
        
        runAndWaitIntrospect(config: validConfig, token: "test_token") { isValid, error in
            XCTAssertNil(isValid)
            XCTAssertEqual(
                OktaError.APIError("Test Error").localizedDescription,
                error?.localizedDescription
            )
        }
    }
    
    func testRunIntrospectionEndpointURL() {
        let config = try! OktaAuthConfig(with: [
            "clientId" : "test_client_id",
            "issuer" : "http://test.issuer.com/",
            "scopes" : "test",
            "redirectUri" : "test:/callback"
        ])
        
        apiMock.configure(response: ["active": true]) { request in
            XCTAssertEqual(
                "http://test.issuer.com/oauth2/v1/introspect",
                request.url?.absoluteString
            )
        }
        
        runAndWaitIntrospect(config: config, token: "test_token") { payload, error in
            XCTAssertNil(error)
            XCTAssertEqual(true, payload?["active"] as? Bool)
        }
    }
    
    func testRunIntrospectionEndpointURLWithOAth2() {
        let config = try! OktaAuthConfig(with: [
            "clientId" : "test_client_id",
            "issuer" : "http://test.issuer.com/oauth2/default",
            "scopes" : "test",
            "redirectUri" : "test:/callback"
        ])
        
        apiMock.configure(response: ["active": true]) { request in
            XCTAssertEqual(
                "http://test.issuer.com/oauth2/default/v1/introspect",
                request.url?.absoluteString
            )
        }
        
        runAndWaitIntrospect(config: config, token: "test_token") { payload, error in
            XCTAssertNil(error)
            XCTAssertEqual(true, payload?["active"] as? Bool)
        }
    }
    
    // MARK: - Utils
    
    private func runAndWaitIntrospect(config: OktaAuthConfig,
                                      token: String?,
                                      validationHandler: @escaping ([String : Any]?, OktaError?) -> Void) {
        let ex = expectation(description: "Introspect should be called!")
        IntrospectTask(token: token, config: config, oktaAPI: apiMock).run { payload, error in
            validationHandler(payload, error)
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
