import XCTest
@testable import OktaAuth

class OktaAppAuthTests: XCTestCase {

    private let issuer = ProcessInfo.processInfo.environment["ISSUER"]!
    private let clientId = ProcessInfo.processInfo.environment["CLIENT_ID"]!
    private let redirectUri = ProcessInfo.processInfo.environment["REDIRECT_URI"]!
    private let logoutRedirectUri = ProcessInfo.processInfo.environment["LOGOUT_REDIRECT_URI"]!
    
    private var envConfig: OktaAuthConfig? {
        return try? OktaAuthConfig(with:[
            "issuer": issuer,
            "clientId": clientId,
            "redirectUri": redirectUri,
            "logoutRedirectUri": logoutRedirectUri,
            "scopes": "openid profile offline_access"
        ])
    }
    
    func testCreationWithNil() {
        // Depends on whether Okta.plist is configured or not
        if let defaultConfig = try? OktaAuthConfig.default() {
            let oktaAuth = try? OktaAppAuth()
            XCTAssertNotNil(oktaAuth)
            XCTAssertEqual(defaultConfig, oktaAuth?.configuration)
        } else {
            XCTAssertThrowsError(try OktaAppAuth()) { error in
                XCTAssertEqual(
                    OktaError.notConfigured.localizedDescription,
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

        let oktaAuth = try? OktaAppAuth(configuration: envConfig)
        XCTAssertNotNil(oktaAuth)
    }
}
