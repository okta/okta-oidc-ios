import UIKit
import XCTest
@testable import OktaAuth
import AppAuth

class Tests: XCTestCase {
    let TOKEN_EXPIRATION_WAIT: UInt32 = 5

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()

        // Revert stored values
        OktaAuth.tokens?.clear()
        OktaAuth.configuration = nil
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
        XCTAssertEqual(additionalParams!, ["nonce": "abbbbbbbc"])
    }

    func testAdditionalParamParseWithNoChange() {
        // Ensure known values from the config object are removed
        let config = [ "nonce": "abbbbbbbc" ]

        let additionalParams = Utils.parseAdditionalParams(config)
        XCTAssertEqual(additionalParams!, config)
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
            XCTAssertEqual(error?.localizedDescription, OktaError.noBearerToken.localizedDescription)
        }
    }

    func testRevokeWithoutToken() {
        // Verify an error is returned if the accessToken is not included
        OktaAuth.configuration = [
            "issuer": "https://example.com/oauth2/default"
        ]
        let _ = Revoke(token: nil) { response, error in
            XCTAssertEqual(error?.localizedDescription, OktaError.noBearerToken.localizedDescription)
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

    func testTokenManagerStorageNoValidation() {
        // Validate that the tokenManager object can be created
        let validTokenExpectation = expectation(description: "Will return a tokenManager object without error")
        TestUtils.tokenManagerNoValidation
        .then { tokenManager in
            self.assertTokenManagerContents(tokenManager)
            validTokenExpectation.fulfill()
        }
        .catch { error in XCTFail(error.localizedDescription) }

        waitForIt()
    }

    func testExpiredIdToken() {
        // Verify an expired token will be caught when validating
        let expiredExpectation = expectation(description: "Will return an undefined idToken because JWT is expired")
        TestUtils.tokenManager
        .then { tokenManager in
            XCTAssertEqual(tokenManager.idToken, nil)
            expiredExpectation.fulfill()
        }

        waitForIt()
    }

    func testReturningTokensFromTokenManager() {
        // Validate that mock token manager returns a null token
        let validTokensExpectation = expectation(description: "Will return tokens without errors")
        TestUtils.tokenManagerNoValidation
        .then { tokenManager in
            self.assertTokenManagerContents(tokenManager)
            validTokensExpectation.fulfill()
        }
        .catch { error in XCTFail(error.localizedDescription) }

        waitForIt()
    }

    func testReturningExpiredTokensFromTokenManager() {
        // Validate that mock token manager returns a null token
        let validTokensExpectation = expectation(description: "Will return tokens without errors")
        TestUtils.tokenManagerNoValidation
        .then { tokenManager in
            self.assertTokenManagerContents(tokenManager)
            validTokensExpectation.fulfill()
        }
        .catch { error in XCTFail(error.localizedDescription) }

        waitForIt(10)

        // Wait for tokens to expire and update validation options to check for expiration
        sleep(TOKEN_EXPIRATION_WAIT)

        XCTAssertEqual(OktaAuth.tokens?.accessToken, nil)
        XCTAssertEqual(OktaAuth.tokens?.idToken, nil)
    }

    func testStoreAndDeleteOfAuthState() {
        // Validate the authState is properly stored and can be removed
        let validTokensExpectation = expectation(description: "Will return tokens without errors")
        TestUtils.tokenManagerNoValidation
        .then { tokenManager in
            OktaAuthorization().storeAuthState(tokenManager)
            validTokensExpectation.fulfill()
        }

        waitForIt()

        self.assertAuthenticationState(OktaAuth.tokens!)

        // Clear the authState
        OktaAuth.tokens?.clear()

        XCTAssertThrowsError(try OktaKeychain.get(key: "OktaAuthStateTokenManager") as Data) { error in
            // Expect "Not found" exception
            XCTAssertEqual(error.localizedDescription, "The operation couldn’t be completed. (OktaAuth.OktaKeychainError error 0.)")
        }
    }

    func testIsAuthenticated() {
        // Validate that if there is an existing accessToken, we return an "authenticated" state
        let isAuthExpectation = expectation(description: "Will correctly return authenticated state")
        TestUtils.tokenManagerNoValidation
        .then { tokenManager in
            OktaAuthorization().storeAuthState(tokenManager)
            isAuthExpectation.fulfill()
        }
        .catch { error in XCTFail(error.localizedDescription) }

        waitForIt()

        let isAuth = OktaAuth.isAuthenticated()
        XCTAssertTrue(isAuth)
    }

    func testIsNotAuthenticated() {
        // Validate that if there is an existing accessToken, we return an "authenticated" state
        let isAuthExpectation = expectation(description: "Will correctly return authenticated state")
        TestUtils.tokenManagerNoValidationWithExpiration
            .then { tokenManager in
                OktaAuthorization().storeAuthState(tokenManager)
                isAuthExpectation.fulfill()
            }
            .catch { error in XCTFail(error.localizedDescription) }

        waitForIt()

        // Wait for tokens to expire
        sleep(TOKEN_EXPIRATION_WAIT)

        let isAuth = OktaAuth.isAuthenticated()
        XCTAssertFalse(isAuth)
    }

    func testRefreshTokenFailure() {
        // Expect that no refresh token stored will result in an error
        let refreshExpectation = expectation(description: "Will fail attempting to refresh tokens")

        OktaAuth.refresh()
        .catch { error in
            XCTAssertEqual(error.localizedDescription, OktaError.noTokens.localizedDescription)
            refreshExpectation.fulfill()
        }

        waitForIt()
    }

    func testRefreshTokenFailureInvalidToken() {
        // TODO: Look into a better way to mock out responses from the AppAuth lib
    }

    func testResumeAuthenticationStateFromExpiredState() {
        // Validate that if there is an existing accessToken, we return an "authenticated" state
        let isAuthExpectation = expectation(description: "Will correctly return authenticated state")
        TestUtils.tokenManagerNoValidationWithExpiration
            .then { tokenManager in
                OktaAuthorization().storeAuthState(tokenManager)
                isAuthExpectation.fulfill()
            }
            .catch { error in XCTFail(error.localizedDescription) }

        waitForIt()

        // Wait for tokens to expire
        sleep(TOKEN_EXPIRATION_WAIT)

        // Re-store the authState
        OktaAuthorization().storeAuthState(OktaAuth.tokens!)

        self.assertAuthenticationState(OktaAuth.tokens!)
    }

    // Helpers for asserting unit tests
    func waitForIt(_ seconds: TimeInterval = 5) {
        // XCTest Utility method to wait for expected conditions
        waitForExpectations(timeout: seconds, handler: { error in
            // Fail on timeout
            if error != nil { XCTFail(error!.localizedDescription) }
        })
    }

    func assertTokenManagerContents(_ tm: OktaTokenManager) {
        XCTAssertEqual(tm.accessToken, TestUtils.mockAccessToken)
        XCTAssertEqual(tm.refreshToken, TestUtils.mockRefreshToken)
    }

    func assertAuthenticationState(_ tm: OktaTokenManager) {
        guard let prevState = TestUtils.getPreviousState() else {
            return XCTFail("Previous authentication state does not exist")
        }

        XCTAssertEqual(prevState.accessibility, tm.accessibility)
        XCTAssertEqual(prevState.accessToken, tm.accessToken)
        XCTAssertEqual(prevState.config, tm.config)
        XCTAssertEqual(prevState.idToken, tm.idToken)
        XCTAssertEqual(prevState.refreshToken, tm.refreshToken)
    }
}
