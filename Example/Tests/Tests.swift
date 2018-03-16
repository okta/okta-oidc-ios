import UIKit
import XCTest
@testable import OktaAuth
import AppAuth
import Vinculum

class Tests: XCTestCase {
    override func setUp() {
        super.setUp()
        OktaAuth.tokens?.clear()

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

        OktaAuth.login("user@example.com", password: "password")
        .start(withPListConfig: "Okta-PasswordFlow", view: UIViewController())
        .catch { error in
            XCTAssertEqual(
                error.localizedDescription,
                "Authorization Error: The operation couldn’t be completed. (org.openid.appauth.general error -6.)"
            )
            pwdExpectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: { error in
            // Fail on timeout
            if error != nil { XCTFail(error!.localizedDescription) }
       })
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

    func testUserInfoWithoutToken() {
        // Verify an error is returned if the accessToken is not included
        OktaAuth.configuration = [
            "issuer": "https://example.com/oauth2/default"
        ]
        let _ = UserInfo(token: nil) { response, error in
            XCTAssertEqual(error?.localizedDescription, "Missing Bearer token. You must authenticate first.")
        }
    }

    func testRevokeWithoutToken() {
        // Verify an error is returned if the accessToken is not included
        OktaAuth.configuration = [
            "issuer": "https://example.com/oauth2/default"
        ]

        let _ = Revoke(token: nil) { response, error in
            XCTAssertEqual(error?.localizedDescription, "Missing Bearer token. You must authenticate first.")
        }
    }

    func testIdTokenDecode() {
        // Expect that a provided token is parseable
        let idToken =
            "fakeHeader.eyJ2ZXIiOjEsImp0aSI6IkFULkNyNW55SFMtdTZwTjNaaDQ2cURJNTJBYmtCMkdoS3FzUEN" +
            "CN3NsdVplR2MuN1NwTms3Wk9HQ3pnL04zdlhuRXcybTdGNjdwMm5CTktoUnF0VEVpc0UxTT0iLCJpc3MiO" +
            "iJodHRwczovL2V4YW1wbGUuY29tIiwiYXVkIjoiYXBpOi8vZGVmYXVsdCIsImlhdCI6MTUxOTk2MDcxOSw" +
            "iZXhwIjoxNTE5OTcyNTA4LCJjaWQiOiJ7Y2xpZW50SWR9IiwidWlkIjoie3VpZH0iLCJzY3AiOlsib3Blb" +
            "mlkIiwib2ZmbGluZV9hY2Nlc3MiLCJwcm9maWxlIl0sInN1YiI6ImV4YW1wbGVAZXhhbXBsZS5jb20ifQ." +
            "fakeSignature"

        Introspect().decode(idToken)
        .then { response in
            XCTAssertNotNil(response)
        }
    }

    func testIsAuthenticated() {
        // Validate that if there is an existing accessToken, we return an "authenticated" state
        let tokenManager = TestUtils.tokenManager
        OktaAuthorization().storeAuthState(tokenManager)
        let isAuth = OktaAuth.isAuthenticated()
        XCTAssertFalse(isAuth)
    }

    func testReturningTokensFromTokenManager() {
        // Validate that mock token manager returns a null token
        let tokenManager = TestUtils.tokenManager
        let accessToken = tokenManager.accessToken
        let idToken = tokenManager.idToken
        let refreshToken = tokenManager.refreshToken
        XCTAssertNil(accessToken)
        XCTAssertNil(idToken)
        XCTAssertNil(refreshToken)
    }

    func testStoreAndDeleteOfAuthState() {
        // Validate the authState is properly stored and can be removed
        OktaAuthorization().storeAuthState(TestUtils.tokenManager)

        let previousState = TestUtils.getPreviousState()
        XCTAssertNotNil(previousState)

        // Clear the authState
        OktaAuth.tokens?.clear()

        XCTAssertThrowsError(try Vinculum.get("OktaAuthStateTokenManager")) { error in
            // Expect "Not found" exception
            XCTAssertEqual(error.localizedDescription, "Error retrieving from Keychain: -25300")
        }

    }
}
