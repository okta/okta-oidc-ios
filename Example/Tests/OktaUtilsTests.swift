import XCTest
@testable import OktaAuth

class OktaUtilsTests: XCTestCase {
    func testPListFormatWithTrailingSlash() {
        // Validate the PList issuer
        let dict = [
            "issuer": "https://example.com/oauth2/authServerId/"
        ]
        let issuer = Utils.removeTrailingSlash(dict["issuer"]!)
        XCTAssertEqual(issuer, "https://example.com/oauth2/authServerId")
    }

    func testPListFormatWithoutTrailingSlash() {
        // Validate the PList issuer
        let dict = [
            "issuer": "https://example.com/oauth2/authServerId"
        ]
        let issuer = Utils.removeTrailingSlash(dict["issuer"]!)
        XCTAssertEqual(issuer, "https://example.com/oauth2/authServerId")
    }

    func testValidScopesString() {
        // Validate the scopes are in the correct format
        let scopes = "openid profile email"
        let validScopes = ["openid", "profile", "email"]
        let scrubbedScopes = Utils.scrubScopes(scopes)
        XCTAssertEqual(scrubbedScopes, validScopes)
    }

    func testAddingOpenIDScopes() {
        // Validate that scopes not including "openid" get appended
        let scopes = "profile email"
        XCTAssertEqual(Utils.scrubScopes(scopes), ["profile", "email", "openid"])
    }
}
