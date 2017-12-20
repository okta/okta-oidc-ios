import UIKit
import XCTest
import OktaAuth

class Tests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
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
        let rv = Utils.validatePList(dict)
        if let issuer = rv?["issuer"] as? String {
            XCTAssertEqual(issuer, "https://example.com/oauth2/authServerId")
        } else {
            XCTFail()
        }

    }

    func testPListFormatWithoutTrailingSlash() {
        // Validate the PList issuer
        let dict = [
            "issuer": "https://example.com/oauth2/authServerId"
        ]
        let rv = Utils.validatePList(dict)
        if let issuer = rv?["issuer"] as? String {
            XCTAssertEqual(issuer, "https://example.com/oauth2/authServerId")
        } else {
            XCTFail()
        }
    }

    func testNoPListOnLogin() {
        let plistException = expectation(description: "Will error attempting find plist")

        OktaAuth
            .login("user@example.com", password: "password")
            .start(withPListConfig: nil, view: UIViewController()) { response, error in
                XCTAssertEqual(error!.localizedDescription, "PList name required. See https://github.com/okta/okta-sdk-appauth-ios/#configuration for more information.")
                plistException.fulfill()
        }

        waitForExpectations(timeout: 20, handler: { error in
            // Fail on timeout
            if error != nil { XCTFail() }
        })
    }

    func testValidScopesArray() {
        // Validate the scopes are in the correct format
        let scopes = ["openid"]
        let scrubbedScopes = try? Utils.scrubScopes(scopes)
        XCTAssertEqual(scrubbedScopes!, scopes)
    }

    func testValidScopesString() {
        // Validate the scopes are in the correct format
        let scopes = "openid profile email"
        let validScopes = ["openid", "profile", "email"]
        let scrubbedScopes = try? Utils.scrubScopes(scopes)
        XCTAssertEqual(scrubbedScopes!, validScopes)
    }

    func testInvalidScopes() {
        // Validate that scopes of wrong type throw an error
        let scopes = [1, 2, 3]
        XCTAssertThrowsError(try Utils.scrubScopes(scopes)) { error in
            let desc = error as! OktaError
            XCTAssertEqual(desc.localizedDescription, "Scopes are in unspecified format. Must be an Array or String type.")
        }
    }

    func testPasswordFailureFlow() {
        // Validate the username & password flow fails without clientSecret
        _ = Utils.getPlistConfiguration(forResourceName: "Okta-PasswordFlow")

        let pwdExpectation = expectation(description: "Will error attempting username/password auth")

        OktaAuth
            .login("user@example.com", password: "password")
            .start(withPListConfig: "Okta-PasswordFlow", view: UIViewController()) { response, error in
                XCTAssertEqual(error!.localizedDescription, "Authorization Error: The operation couldn’t be completed. (org.openid.appauth.general error -6.)")
                pwdExpectation.fulfill()
        }

        waitForExpectations(timeout: 20, handler: { error in
            // Fail on timeout
            if error != nil { XCTFail() }
       })
    }

    func testKeychainStorage() {
        // Validate that tokens can be stored and retrieved via the keychain
        let tokens = OktaTokenManager(authState: nil)

        tokens.set(value: "fakeToken", forKey: "accessToken")
        XCTAssertNotNil(tokens.get(forKey: "accessToken"))

        // Clear tokens
        tokens.clear()
        XCTAssertNil(tokens.get(forKey: "accessToken"))
    }

    func testBackgroundKeychainStorage() {
        // Validate that tokens can be stored and retrieved via the keychain
        let tokens = OktaTokenManager(authState: nil)

        tokens.set(value: "fakeToken", forKey: "accessToken", needsBackgroundAccess: true)
        XCTAssertNotNil(tokens.get(forKey: "accessToken"))

        // Clear tokens
        tokens.clear()
        XCTAssertNil(tokens.get(forKey: "accessToken"))
    }
}
