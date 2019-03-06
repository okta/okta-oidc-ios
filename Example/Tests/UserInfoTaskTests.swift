import XCTest
@testable import OktaAuth

class UserInfoTaskTests: XCTestCase {

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
        
        apiMock.configure(response: ["username": "test"])
        
        runAndWaitUserInfo(config: config, token: "test_token") { userInfo, error in
            XCTAssertNil(error)
            XCTAssertEqual(false, userInfo?.isEmpty)
        }
    }

    func testRunNotConfigured() {
        apiMock.configure(response: [:]) { request in
            XCTFail("Should not make a request to API!")
        }
        
        runAndWaitUserInfo(config: nil, token: "test_token") { userInfo, error in
            XCTAssertNil(userInfo)
            XCTAssertEqual(
                OktaError.notConfigured.localizedDescription,
                error?.localizedDescription
            )
        }
    }
    
    func testRunNoUserInfoEndpoint() {
        // value for "issuer" missing
        let config = OktaAuthConfig(with: [:])
    
        apiMock.configure(response: [:]) { request in
            XCTFail("Should not make a request to API!")
        }
    
        runAndWaitUserInfo(config: config, token: "test_token") { userInfo, error in
            XCTAssertNil(userInfo)
            XCTAssertEqual(
                OktaError.noUserInfoEndpoint.localizedDescription,
                error?.localizedDescription
            )
        }
    }
    
    func testRunNoBearerToken() {
        let config = OktaAuthConfig(with: ["issuer" : "http://test.issuer.com/oauth2/default"])
        
        apiMock.configure(response: [:]) { request in
            XCTFail("Should not make a request to API!")
        }
        
        runAndWaitUserInfo(config: config, token: nil) { userInfo, error in
            XCTAssertNil(userInfo)
            XCTAssertEqual(
                OktaError.noBearerToken.localizedDescription,
                error?.localizedDescription
            )
        }
    }
    
    func testRunApiError() {
        let config = OktaAuthConfig(with: ["issuer" : "http://test.issuer.com/oauth2/default"])
        
        apiMock.configure(error: OktaError.APIError("Test Error"))
        
        runAndWaitUserInfo(config: config, token: "test_token") { userInfo, error in
            XCTAssertNil(userInfo)
            XCTAssertEqual(
                OktaError.APIError("Test Error").localizedDescription,
                error?.localizedDescription
            )
        }
    }
    
    func testRunUseInfoEndpointURL() {
        let config = OktaAuthConfig(with: ["issuer" : "http://test.issuer.com/"])
        
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
        let config = OktaAuthConfig(with: ["issuer" : "http://test.issuer.com/oauth2/default"])
        
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
    
    private func runAndWaitUserInfo(config: OktaAuthConfig?,
                                      token: String?,
                                      validationHandler: @escaping ([String:Any]?, OktaError?) -> Void) {
        let ex = expectation(description: "User Info should be called!")
        UserInfoTask(config: config, token: token).run { userInfo, error in
            validationHandler(userInfo, error)
            ex.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }
}
