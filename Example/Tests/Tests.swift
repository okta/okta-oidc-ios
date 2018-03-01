import UIKit
import XCTest
@testable import OktaAuth

class Tests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        OktaAuth.tokens?.clear()
    }

    func testPListFailure() {
        // Attempt to find a plist file that does not exist
        XCTAssertNil(Utils.getPlistConfiguration(forResourceName: "noFile"))
    }

    func testPListFound() {
        // Attempt to find the Okta.plist file
        XCTAssertNotNil(Utils.getPlistConfiguration())
    }

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

    func testAdditionalParamParse() {
        // Ensure known values from the config object are removed
        let config = [
            "issuer": "https://example.com/oauth2/default",
            "clientId": "clientId",
            "redirectUri": "com.okta.example:/callback",
            "scopes": "openid profile offline_access",
            "nonce": "abbbbbbbc"
        ]

        let additionalParams = Utils.parseAdditionalParams(config)
        XCTAssertNil(additionalParams?["issuer"])
        XCTAssertNil(additionalParams?["clientId"])
        XCTAssertNil(additionalParams?["redirectUri"])
        XCTAssertNil(additionalParams?["scopes"])
        XCTAssertNotNil(additionalParams?["nonce"])
    }

    func testAdditionalParamParseWithNoChange() {
        // Ensure known values from the config object are removed
        let config = [  "nonce": "abbbbbbbc" ]

        let additionalParams = Utils.parseAdditionalParams(config)
        XCTAssertNotNil(additionalParams?["nonce"])
        XCTAssertEqual(config, additionalParams!)
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

    func testPasswordFailureFlow() {
        // Validate the username & password flow fails without clientSecret
        _ = Utils.getPlistConfiguration(forResourceName: "Okta-PasswordFlow")

        let pwdExpectation = expectation(description: "Will error attempting username/password auth")

        OktaAuth
            .login("user@example.com", password: "password")
            .start(withPListConfig: "Okta-PasswordFlow", view: UIViewController()) { response, error in
                XCTAssertEqual(
                    error!.localizedDescription,
                    "Authorization Error: The operation couldn’t be completed. (org.openid.appauth.general error -6.)"
                )
                pwdExpectation.fulfill()
        }

        waitForExpectations(timeout: 3, handler: { error in
            // Fail on timeout
            if error != nil { XCTFail(error!.localizedDescription) }
       })
    }

    func testKeychainStorage() {
        // Validate that tokens can be stored and retrieved via the keychain
        let tokens = OktaTokenManager(authState: nil)

        tokens.set(value: "fakeToken", forKey: "accessToken")
        XCTAssertEqual(tokens.get(forKey: "accessToken"), "fakeToken")

        // Clear tokens
        tokens.clear()
        XCTAssertNil(tokens.get(forKey: "accessToken"))
    }

    func testBackgroundKeychainStorage() {
        // Validate that tokens can be stored and retrieved via the keychain
        let tokens = OktaTokenManager(authState: nil)

        tokens.set(value: "fakeToken", forKey: "accessToken", needsBackgroundAccess: true)
        XCTAssertEqual(tokens.get(forKey: "accessToken"), "fakeToken")

        // Clear tokens
        tokens.clear()
        XCTAssertNil(tokens.get(forKey: "accessToken"))
    }

    func testIntrospectionEndpointURL() {
        // Similar use case for revoke and userinfo endpoints
        OktaAuth.configuration = [
            "issuer": "https://example.com"
        ]
        let url = Introspect().getIntrospectionEndpoint()
        XCTAssertEqual(url?.absoluteString, "https://example.com/oauth2/v1/introspect")
    }

    func testIntrospectionEndpointURLWithOAuth2() {
        // Similar use case for revoke and userinfo endpoints
        OktaAuth.configuration = [
            "issuer": "https://example.com/oauth2/default"
        ]
        let url = Introspect().getIntrospectionEndpoint()
        XCTAssertEqual(url?.absoluteString, "https://example.com/oauth2/default/v1/introspect")
    }
}
