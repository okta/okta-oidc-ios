import UIKit
import XCTest
import OktaAuth

class Tests: XCTestCase {
    override func setUp() {
        super.setUp()
        _ = Utils.getPlistConfiguration()
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
            // Fail
            XCTAssertEqual(true, false)
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
            // Fail
            XCTAssertEqual(true, false)
        }
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
        XCTAssertThrowsError(try Utils.scrubScopes(scopes))
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
    
    func testKeysEndpoint() {
        // Attempt to hit the keys endpoint based on PList configuration
        
        let keysExpectation = expectation(description: "GET /keys endpoint")
        OktaJWTValidator.getKeys() { response in
            XCTAssertNotNil(response)
            keysExpectation.fulfill()
        }
        waitForExpectations(timeout: 20, handler: { error in
            // Fail on timeout
            if error != nil { XCTAssertNotNil(nil) }
        })
    }
    
    func testInvalidToken() {
        // Attempt to validate an invalid token
        
        let token = "eyJhbGciOiJSUzI1NiIsImtpZCI6InIzeGlQeGR1X2NzSVhRT2FlR3FDb" +
            "TNRejVCU2ZheGYwNFNBWWJXSXNVNVkifQ.eyJzdWIiOiIwMHU2YW4xejdlSVBhVmx" +
            "0RzBoNyIsIm5hbWUiOiJKb3JkYW4gTWVsYmVyZyIsInZlciI6MSwiaXNzIjoiaHR0cH" +
            "M6Ly9qb3JkYW5kZW1vLm9rdGFwcmV2aWV3LmNvbS9vYXV0aDIvYXVzOXd0dWZjOEw" +
            "wNDFxajUwaDciLCJhdWQiOiJKdzFueXpic05paFN1T0VUWTNSMSIsImlhdCI6MTUw" +
            "MjA4NDI4NSwiZXhwIjoxNTAyMDg3ODg1LCJqdGkiOiJJRC44TFhiLW1pWG1nNVZfUF" +
            "pXQWZ3RUpFY0tIamJIRUdIQXlHTjhEWUZsRDRNIiwiYW1yIjpbInB3ZCJdLCJpZHAi" +
            "OiIwMG82YW4wc3Fqc1c3WEtQQTBoNyIsInByZWZlcnJlZF91c2VybmFtZSI6ImpvcmR" +
            "hbi5tZWxiZXJnQGdtYWlsLmNvbSIsImF1dGhfdGltZSI6MTUwMjA4NDI4MywiYXRfa" +
            "GFzaCI6InhORERwTTVVVi1rVjZvYzA2cGFFclEifQ.nid3T8n5uAR3XG-d3OAFwyhdoX" +
            "seysfK5oNFS9x1R3I7StJ4WE-TinwbzL9El0icCnApVKFTjSj81SM6cOCGzcxGWGyALKQtuA2" +
            "FdpQHTw3vfDRvGKnztal300nbDvQN9oyZjhqBEe1uFkn4Gk1_xcWlVTbyvH-isVnyYcIfGwrALJa7OYV" +
            "zQzf8jtIRdhgylWQAwBFIInH_B8GyK1zhQvKfUXY2CXWx5BNVGznexDwxfO9xy3" +
            "qRYKWxkbVzHfC_hGvXnSZYgp1Go-Fxms3KiYJjM7J8wGD2GU_fS0gGdC4rC5PCHsY7V" +
            "f4cgsxHcZ8pWsEweERdWZ1sl5RD3jGGLQ"
        
        let tokenExpectation = expectation(description: "Test invalid token")
        
        _ = OktaAuth.validateToken(token) { response, error in
            
            if error != nil {
                let expectedError = OktaError.jwtValidationError(error: "The JWT expired and is no longer valid").localizedDescription
                XCTAssertEqual(error!.localizedDescription, expectedError)
            } else {
                XCTAssertNotNil(nil)
            }
            tokenExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 20, handler: { error in
            // Fail on timeout
            if error != nil { XCTAssertNotNil(nil) }
        })
    }
}
