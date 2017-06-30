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
    
    func testPListFormatWithTrailingSlash() {
        // Validate the PList issuer
        let dict = [
            "issuer": "https://example.com/oauth2/authServerId/"
        ]
        let rv = Utils().validatePList(dict)
        if let issuer = rv?["issuer"] as? String {
            XCTAssertEqual(issuer, "https://example.com/oauth2/authServerId")
        } else {
            // Fail
            XCTAssertEqual(true, false)
        }
        
    }
    
    func testPListFormatWithoutTrailingSlash() {
        // Validate the PList issuer
        let dict = [
            "issuer": "https://example.com/oauth2/authServerId"
        ]
        let rv = Utils().validatePList(dict)
        if let issuer = rv?["issuer"] as? String {
            XCTAssertEqual(issuer, "https://example.com/oauth2/authServerId")
        } else {
            // Fail
            XCTAssertEqual(true, false)
        }
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
    
    func testTokenIntrospectionWithoutValidation() {
        // Verify we can parse an id_token without validation
        let token = "eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiIwMHVpZDRCeFh3Nkk2VFY0bTBnMyI" +
        "sImVtYWlsIjoid2VibWFzdGVyQGNsb3VkaXR1ZGUubmV0IiwiZW1haWxfdmVyaWZpZWQ" +
        "iOnRydWUsInZlciI6MSwiaXNzIjoiaHR0cDovL3JhaW4ub2t0YTEuY29tOjE4MDIiLCJ" +
        "sb2dpbiI6ImFkbWluaXN0cmF0b3IxQGNsb3VkaXR1ZGUubmV0IiwiYXVkIjoidUFhdW5" +
        "vZldrYURKeHVrQ0ZlQngiLCJpYXQiOjE0NDk2MjQwMjYsImV4cCI6MTQ0OTYyNzYyNiw" +
        "iYW1yIjpbInB3ZCJdLCJqdGkiOiI0ZUFXSk9DTUIzU1g4WGV3RGZWUiIsImF1dGhfdGl" +
        "tZSI6MTQ0OTYyNDAyNiwiYXRfaGFzaCI6ImNwcUtmZFFBNWVIODkxRmY1b0pyX1EifQ." +
        "Btw6bUbZhRa89DsBb8KmL9rfhku--_mbNC2pgC8yu8obJnwO12nFBepui9KzbpJhGM91" +
        "PqJwi_AylE6rp-ehamfnUAO4JL14PkemF45Pn3u_6KKwxJnxcWxLvMuuisnvIs7NScKp" +
        "OAab6ayZU0VL8W6XAijQmnYTtMWQfSuaaR8rYOaWHrffh3OypvDdrQuYacbkT0cs" +
        "xdrayXfBG3UF5-ZAlhfch1fhFT3yZFdWwzkSDc0BGygfiFyNhCezfyT454wbciSZgrA9R" +
        "OeHkfPCaX7KCFO8GgQEkGRoQntFBNjluFhNLJIUkEFovEDlfuB4tv_M8BM75celd" +
        "y3jkpOurg"
        
        OktaAuth
            .introspect()
            .withoutValidation(token) { response, error in
                XCTAssertNotNil(response)
                XCTAssertNil(error)
        }
    }
}
