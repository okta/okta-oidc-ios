import XCTest
@testable import OktaAuth

class DiscoveryTaskTests: XCTestCase {

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
        apiMock.configure(response: self.validOIDConfigDictionary)
        
        runAndWaitDiscovery(config: validConfig) { oidConfig, error in
            XCTAssertNil(error)
            XCTAssertNotNil(oidConfig)
        }
    }
    
    func testRunApiError() {
        apiMock.configure(error: OktaError.APIError("Test Error"))
        
        runAndWaitDiscovery(config: validConfig) { oidConfig, error in
            XCTAssertNil(oidConfig)
            XCTAssertEqual(
                "Error returning discovery document: Test Error Pleasecheck your PList configuration",
                error?.localizedDescription
            )
        }
    }
    
    func testRunParseError() {
        apiMock.configure(response: ["invalidKey" : ""])
        
        runAndWaitDiscovery(config: validConfig) { oidConfig, error in
            XCTAssertNil(oidConfig)
            XCTAssertEqual(
                OktaError.parseFailure.localizedDescription,
                error?.localizedDescription
            )
        }
    }
    
    func testRunDiscoveryEndpointURL() {
        apiMock.configure(response: validOIDConfigDictionary) { request in
            XCTAssertEqual(
                "http://test.issuer.com/oauth2/default/.well-known/openid-configuration",
                request.url?.absoluteString
            )
        }
        
        runAndWaitDiscovery(config: validConfig) { oidConfig, error in
            XCTAssertNil(error)
            XCTAssertNotNil(oidConfig)
        }
    }
    
    // MARK: - Utils
    
    private func runAndWaitDiscovery(config: OktaAuthConfig,
                                      validationHandler: @escaping (OIDServiceConfiguration?, OktaError?) -> Void) {
        let ex = expectation(description: "User Info should be called!")
        MetadataDiscovery(config: config, oktaAPI: apiMock).run { oidConfig, error in
            validationHandler(oidConfig, error)
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
