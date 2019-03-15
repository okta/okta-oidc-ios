import XCTest
@testable import OktaAuth

class OktaAuthConfigTests: XCTestCase {
    
    func testCreation() {
        let dict = [
            "clientId" : "test_client_id",
            "issuer" : "test_issuer",
            "scopes" : "test_scope",
            "redirectUri" : "com.test:/callback",
            "logoutRedirectUri" : "com.test:/logout"
        ]
        
        let config: OktaAuthConfig
        do {
            config = try OktaAuthConfig(with: dict)
        } catch let error {
            XCTFail("Unexpected error: \(error)")
            return
        }
        
        XCTAssertEqual("test_client_id", config.clientId)
        XCTAssertEqual("test_issuer", config.issuer)
        XCTAssertEqual("test_scope", config.scopes)
        XCTAssertEqual(URL(string: "com.test:/callback"), config.redirectUri)
        XCTAssertEqual(URL(string: "com.test:/logout"), config.logoutRedirectUri)
        XCTAssertEqual(true, config.additionalParams?.isEmpty)
    }
    
    func testCreationWithAdditionalParams() {
        let dict = [
            "clientId" : "test_client_id",
            "issuer" : "test_issuer",
            "scopes" : "test_scope",
            "redirectUri" : "com.test:/callback",
            "logoutRedirectUri" : "com.test:/logout",
            "additionalParam" : "test_param",
        ]
        
        let config: OktaAuthConfig
        do {
            config = try OktaAuthConfig(with: dict)
        } catch let error {
            XCTFail("Unexpected error: \(error)")
            return
        }
        
        XCTAssertEqual("test_client_id", config.clientId)
        XCTAssertEqual("test_issuer", config.issuer)
        XCTAssertEqual("test_scope", config.scopes)
        XCTAssertEqual(URL(string: "com.test:/callback"), config.redirectUri)
        XCTAssertEqual(URL(string: "com.test:/logout"), config.logoutRedirectUri)

        XCTAssertEqual(1, config.additionalParams?.count)
        XCTAssertEqual("test_param", config.additionalParams?["additionalParam"])
    }
    
    func testDefaultConfig() {
        do {
            let _ = try OktaAuthConfig.default()
        } catch let error {
            XCTAssertEqual(
                OktaError.missingConfigurationValues.localizedDescription,
                error.localizedDescription
            )
        }
    }
    
    func testOktaPlist() {
        do {
            let _ = try OktaAuthConfig(fromPlist: "Okta")
        } catch let error {
            XCTAssertEqual(
                OktaError.missingConfigurationValues.localizedDescription,
                error.localizedDescription
            )
        }
    }
    
    func testNoPListGiven() {
        // name of file which does not exists
        let plistName = UUID().uuidString
        var config: OktaAuthConfig? = nil
        do {
           config = try OktaAuthConfig(fromPlist: plistName)
        } catch let error {
            XCTAssertEqual(
                error.localizedDescription,
                OktaError.noPListGiven.localizedDescription
            )
        }
        
        XCTAssertNil(config)
    }
    
    func testPListParseFailure() {
        // Info.plist does not correspond to expected structure of Okta file
        let plistName = "Info"
        var config: OktaAuthConfig? = nil
        do {
            config = try OktaAuthConfig(fromPlist: plistName)
        } catch let error {
            XCTAssertEqual(
                error.localizedDescription,
                OktaError.pListParseFailure.localizedDescription
            )
        }
        
        XCTAssertNil(config)
    }
}
