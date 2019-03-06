import XCTest
@testable import OktaAuth

class DiscoveryTaskTests: XCTestCase {

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
        let config = OktaAuthConfig(with: ["issuer" : "http://test.issuer.com/oauth2/default"])
        
        apiMock.configure(response: self.validOIDConfigDictionary)
        
        runAndWaitDiscovery(config: config) { oidConfig, error in
            XCTAssertNil(error)
            XCTAssertNotNil(oidConfig)
        }
    }

    func testRunNotConfigured() {
        apiMock.configure(response: [:]) { request in
            XCTFail("Should not make a request to API!")
        }
        
        runAndWaitDiscovery(config: nil) { oidConfig, error in
            XCTAssertNil(oidConfig)
            XCTAssertEqual(
                OktaError.notConfigured.localizedDescription,
                error?.localizedDescription
            )
        }
    }
    
    func testRunNoDiscoveryEndpoint() {
        // value for "issuer" missing
        let config = OktaAuthConfig(with: [:])
    
        apiMock.configure(response: [:]) { request in
            XCTFail("Should not make a request to API!")
        }
    
        runAndWaitDiscovery(config: config) { oidConfig, error in
            XCTAssertNil(oidConfig)
            XCTAssertEqual(
                OktaError.noDiscoveryEndpoint.localizedDescription,
                error?.localizedDescription
            )
        }
    }
    
    func testRunApiError() {
        let config = OktaAuthConfig(with: ["issuer" : "http://test.issuer.com/oauth2/default"])
        
        apiMock.configure(error: OktaError.APIError("Test Error"))
        
        runAndWaitDiscovery(config: config) { oidConfig, error in
            XCTAssertNil(oidConfig)
            XCTAssertEqual(
                "Error returning discovery document: Test Error Pleasecheck your PList configuration",
                error?.localizedDescription
            )
        }
    }
    
    func testRunParseError() {
        let config = OktaAuthConfig(with: ["issuer" : "http://test.issuer.com/oauth2/default"])
        
        apiMock.configure(response: ["invalidKey" : ""])
        
        runAndWaitDiscovery(config: config) { oidConfig, error in
            XCTAssertNil(oidConfig)
            XCTAssertEqual(
                OktaError.parseFailure.localizedDescription,
                error?.localizedDescription
            )
        }
    }
    
    func testRunDiscoveryEndpointURL() {
        let config = OktaAuthConfig(with: ["issuer" : "http://test.issuer.com"])
        
        apiMock.configure(response: validOIDConfigDictionary) { request in
            XCTAssertEqual(
                "http://test.issuer.com/.well-known/openid-configuration",
                request.url?.absoluteString
            )
        }
        
        runAndWaitDiscovery(config: config) { oidConfig, error in
            XCTAssertNil(error)
            XCTAssertNotNil(oidConfig)
        }
    }
    
    // MARK: - Utils
    
    private func runAndWaitDiscovery(config: OktaAuthConfig?,
                                      validationHandler: @escaping (OIDServiceConfiguration?, OktaError?) -> Void) {
        let ex = expectation(description: "User Info should be called!")
        MetadataDiscovery(config: config).run { oidConfig, error in
            validationHandler(oidConfig, error)
            ex.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    private var validOIDConfigDictionary: [String:Any] {
        return [
            "issuer" : "http://test.issuer.com/oauth2/default",
            "authorization_endpoint" : "http://test.issuer.com/oauth2/authorize",
            "token_endpoint" : "http://test.issuer.com/oauth2/token",
            "jwks_uri" : "http://test.issuer.com/oauth2/default/v1/keys",
            "response_types_supported" : ["code"],
            "subject_types_supported" : ["public"],
            "id_token_signing_alg_values_supported" : ["RS256"]
        ]
    }
}
