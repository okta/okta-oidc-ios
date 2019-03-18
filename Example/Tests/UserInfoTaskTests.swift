import XCTest
@testable import OktaAuth

class UserInfoTaskTests: XCTestCase {

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
        apiMock.configure(response: ["username": "test"])
        
        runAndWaitUserInfo(config: validConfig, token: "test_token") { userInfo, error in
            XCTAssertNil(error)
            XCTAssertEqual(false, userInfo?.isEmpty)
        }
    }
    
    func testRunNoBearerToken() {
        apiMock.configure(response: [:]) { request in
            XCTFail("Should not make a request to API!")
        }
        
        runAndWaitUserInfo(config: validConfig, token: nil) { userInfo, error in
            XCTAssertNil(userInfo)
            XCTAssertEqual(
                OktaError.noBearerToken.localizedDescription,
                error?.localizedDescription
            )
        }
    }
    
    func testRunApiError() {
        apiMock.configure(error: OktaError.APIError("Test Error"))
        
        runAndWaitUserInfo(config: validConfig, token: "test_token") { userInfo, error in
            XCTAssertNil(userInfo)
            XCTAssertEqual(
                OktaError.APIError("Test Error").localizedDescription,
                error?.localizedDescription
            )
        }
    }
    
    func testRunUseInfoEndpointURL() {
        let config = try! OktaAuthConfig(with: [
            "issuer" : "http://test.issuer.com/",
            "clientId" : "test_client_id",
            "scopes" : "test",
            "redirectUri" : "test:/callback"
        ])
        
        apiMock.configure(response: ["username": "test"]) { request in
            XCTAssertEqual(
                "http://test.issuer.com/oauth2/v1/userinfo",
                request.url?.absoluteString
            )
        }
        
        runAndWaitUserInfo(config: config, token: "test_token") { userInfo, error in
            XCTAssertNil(error)
            XCTAssertEqual(false, userInfo?.isEmpty)
        }
    }
    
    func testRunUseInfoEndpointURLWithOAth2() {
        let config = try! OktaAuthConfig(with: [
            "issuer" : "http://test.issuer.com/oauth2/default",
            "clientId" : "test_client_id",
            "scopes" : "test",
            "redirectUri" : "test:/callback"
        ])
        
        apiMock.configure(response: ["username": "test"]) { request in
            XCTAssertEqual(
                "http://test.issuer.com/oauth2/default/v1/userinfo",
                request.url?.absoluteString
            )
        }
        
        runAndWaitUserInfo(config: config, token: "test_token") { userInfo, error in
            XCTAssertNil(error)
            XCTAssertEqual(false, userInfo?.isEmpty)
        }
    }

    // MARK: - Utils
    
    private func runAndWaitUserInfo(config: OktaAuthConfig,
                                      token: String?,
                                      validationHandler: @escaping ([String:Any]?, OktaError?) -> Void) {
        let ex = expectation(description: "User Info should be called!")
        UserInfoTask(token: token, config: config, oktaAPI: apiMock).run { userInfo, error in
            validationHandler(userInfo, error)
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
