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
        XCTAssertNil(Utils().getPlistConfiguration(forResourceName: "noFile"))
    }

    func testPListFound() {
        // Attempt to find the Okta.plist file
        XCTAssertNotNil(Utils().getPlistConfiguration())
    }

    func testValidScopesArray() {
        // Validate the scopes are in the correct format
        let scopes = ["openid"]
        let scrubbedScopes = try? Utils().scrubScopes(scopes)
        XCTAssertEqual(scrubbedScopes!, scopes)
    }

    func testValidScopesString() {
        // Validate the scopes are in the correct format
        let scopes = "openid profile email"
        let validScopes = ["openid", "profile", "email"]
        let scrubbedScopes = try? Utils().scrubScopes(scopes)
        XCTAssertEqual(scrubbedScopes!, validScopes)
    }

    func testInvalidScopes() {
        // Validate that scopes of wrong type throw an error
        let scopes = [1, 2, 3]
        XCTAssertThrowsError(try Utils().scrubScopes(scopes))
    }

    func testPasswordFailureFlow() {
        // Validate the username & password flow fails without clientSecret
        OktaAuth
            .login("user@example.com", password: "password")
            .start(UIViewController()) { response, error in
                XCTAssertNotNil(error)
                XCTAssertNil(response)
        }
    }

    func testKeyChainStorage() {
        // Validate that tokens can be stored and retrieved via the keychain
        let tokens = OktaTokenManager(authState: nil)

        tokens.set(value: "fakeToken", forKey: "accessToken")
        XCTAssertNotNil(tokens.get(forKey: "accessToken"))

        // Clear tokens
        tokens.clear()
        XCTAssertNil(tokens.get(forKey: "accessToken"))
    }
}
