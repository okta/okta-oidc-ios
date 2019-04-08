import XCTest
@testable import OktaOidc

class OktaOidcConfigTests: XCTestCase {
    
    func testCreation() {
        let dict = [
            "clientId" : "test_client_id",
            "issuer" : "test_issuer",
            "scopes" : "test_scope",
            "redirectUri" : "com.test:/callback",
            "logoutRedirectUri" : "com.test:/logout"
        ]
        
        let config: OktaOidcConfig
        do {
            config = try OktaOidcConfig(with: dict)
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
        
        let config: OktaOidcConfig
        do {
            config = try OktaOidcConfig(with: dict)
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
            let _ = try OktaOidcConfig.default()
        } catch let error {
            XCTAssertEqual(
                OktaOidcError.missingConfigurationValues.localizedDescription,
                error.localizedDescription
            )
        }
    }
    
    func testOktaPlist() {
        do {
            let _ = try OktaOidcConfig(fromPlist: "Okta")
        } catch let error {
            XCTAssertEqual(
                OktaOidcError.missingConfigurationValues.localizedDescription,
                error.localizedDescription
            )
        }
    }
    
    func testNoPListGiven() {
        // name of file which does not exists
        let plistName = UUID().uuidString
        var config: OktaOidcConfig? = nil
        do {
           config = try OktaOidcConfig(fromPlist: plistName)
        } catch let error {
            XCTAssertEqual(
                error.localizedDescription,
                OktaOidcError.noPListGiven.localizedDescription
            )
        }
        
        XCTAssertNil(config)
    }
    
    func testPListParseFailure() {
        // Info.plist does not correspond to expected structure of Okta file
        let plistName = "Info"
        var config: OktaOidcConfig? = nil
        do {
            config = try OktaOidcConfig(fromPlist: plistName)
        } catch let error {
            XCTAssertEqual(
                error.localizedDescription,
                OktaOidcError.pListParseFailure.localizedDescription
            )
        }
        
        XCTAssertNil(config)
    }
}
