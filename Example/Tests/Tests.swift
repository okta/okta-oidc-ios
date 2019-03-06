import UIKit
import XCTest
@testable import OktaAuth

class Tests: XCTestCase {
    let TOKEN_EXPIRATION_WAIT: UInt32 = 5

    override func setUp() {
        super.setUp()
        OktaAuth.configuration = try? OktaAuthConfig.default()
    }

    override func tearDown() {
        super.tearDown()

        // Revert stored values
        OktaAuth.tokens?.clear()
        OktaAuth.configuration = nil
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
    
    func testSignOutOfOktaFailure() {
        let signOutExpectation = expectation(description: "Will error attempting sign out locally")
        
        OktaAuth.signOutOfOkta(from: UIViewController(), callback: { error in
            XCTAssertEqual(
                error?.localizedDescription,
                OktaError.missingConfigurationValues.localizedDescription
            )
            signOutExpectation.fulfill()
        })
        
        waitForExpectations(timeout: 5, handler: { error in
            // Fail on timeout
            if error != nil { XCTFail(error!.localizedDescription) }
        })
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
        
        do {
            let response = try OktaTokenManager.decodeJWT(idToken)
            XCTAssertNotNil(response)
        } catch let error {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExpiredIdToken() {
        // Verify an expired token will be caught when validating
        let tokenManager = TestUtils.tokenManager()
        XCTAssertNil(tokenManager.idToken)
    }

    func testReturningTokensFromTokenManager() {
        // Validate that mock token manager returns a null token
        let tokenManager = TestUtils.tokenManager()
        self.assertTokenManagerContents(tokenManager)
    }

    func testReturningExpiredTokensFromTokenManager() {
        // Validate that mock token manager returns a null token
        let tokenManager = TestUtils.tokenManagerWithExpiration()
        self.assertTokenManagerContents(tokenManager)

        // Wait for tokens to expire and update validation options to check for expiration
        sleep(TOKEN_EXPIRATION_WAIT)

        XCTAssertEqual(OktaAuth.tokens?.accessToken, nil)
        XCTAssertEqual(OktaAuth.tokens?.idToken, nil)
    }

    func testStoreAndDeleteOfAuthState() {
        let tokenManager = TestUtils.tokenManager()
        OktaAuth.tokens = tokenManager

        self.assertAuthenticationState(OktaAuth.tokens!)

        // Clear the authState
        OktaAuth.tokens?.clear()

        XCTAssertNil(OktaTokenManager.readFromSecureStorage())
    }

    func testIsAuthenticated() {
        // Validate that if there is an existing accessToken, we return an "authenticated" state
        let tokenManager = TestUtils.tokenManager()
        OktaAuth.tokens = tokenManager

        let isAuth = OktaAuth.isAuthenticated
        XCTAssertTrue(isAuth)
    }

    func testIsNotAuthenticated() {
        // Validate that if there is an existing accessToken, we return an "authenticated" state
        let tokenManager = TestUtils.tokenManagerWithExpiration()
        OktaAuth.tokens = tokenManager

        // Wait for tokens to expire
        sleep(TOKEN_EXPIRATION_WAIT)

        let isAuth = OktaAuth.isAuthenticated
        XCTAssertFalse(isAuth)
    }

    func testRefreshTokenFailure() {
        // Expect that no refresh token stored will result in an error
        let refreshExpectation = expectation(description: "Will fail attempting to refresh tokens")

        OktaAuth.refresh { _, error in
            XCTAssertEqual(error?.localizedDescription, OktaError.noTokens.localizedDescription)
            refreshExpectation.fulfill()
        }

        waitForIt()
    }

    func testRefreshTokenFailureInvalidToken() {
        // TODO: Look into a better way to mock out responses from the AppAuth lib
    }

    func testResumeAuthenticationStateFromExpiredState() {
        // Validate that if there is an existing accessToken, we return an "authenticated" state
        let tokenManager = TestUtils.tokenManagerWithExpiration()
        OktaAuth.tokens = tokenManager

        // Wait for tokens to expire
        sleep(TOKEN_EXPIRATION_WAIT)

        // Re-store the authState
        OktaAuth.tokens = OktaAuth.tokens!

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
        guard let prevState = OktaTokenManager.readFromSecureStorage() else {
            return XCTFail("Previous authentication state does not exist")
        }

        XCTAssertEqual(prevState.accessibility, tm.accessibility)
        XCTAssertEqual(prevState.accessToken, tm.accessToken)
        XCTAssertEqual(prevState.config, tm.config)
        XCTAssertEqual(prevState.idToken, tm.idToken)
        XCTAssertEqual(prevState.refreshToken, tm.refreshToken)
    }
}
