import XCTest
@testable import OktaOidc

class OktaOidcTests: XCTestCase {

    private let issuer = ProcessInfo.processInfo.environment["ISSUER"]!
    private let clientId = ProcessInfo.processInfo.environment["CLIENT_ID"]!
    private let redirectUri = ProcessInfo.processInfo.environment["REDIRECT_URI"]!
    private let logoutRedirectUri = ProcessInfo.processInfo.environment["LOGOUT_REDIRECT_URI"]!
    
    private var envConfig: OktaOidcConfig? {
        return try? OktaOidcConfig(with:[
            "issuer": issuer,
            "clientId": clientId,
            "redirectUri": redirectUri,
            "logoutRedirectUri": logoutRedirectUri,
            "scopes": "openid profile offline_access"
        ])
    }
    
    func testCreationWithNil() {
        // Depends on whether Okta.plist is configured or not
        if let defaultConfig = try? OktaOidcConfig.default() {
            let oktaOidc = try? OktaOidc()
            XCTAssertNotNil(oktaOidc)
            XCTAssertEqual(defaultConfig, oktaOidc?.configuration)
        } else {
            XCTAssertThrowsError(try OktaOidc()) { error in
                XCTAssertEqual(
                    OktaOidcError.notConfigured.localizedDescription,
                    error.localizedDescription
                )
            }
        }
    }
    
    func testCreationWithEnvConfig() {
        guard let envConfig = envConfig else {
            XCTFail("Please, configure environment variables to create config!")
            return
        }

        let oktaOidc = try? OktaOidc(configuration: envConfig)
        XCTAssertNotNil(oktaOidc)
    }
}
