import UIKit
import XCTest
@testable import OktaAuth

class Tests: XCTestCase {
    let TOKEN_EXPIRATION_WAIT: UInt32 = 5
    
    var oktaAppAuth: OktaAppAuth?

    override func setUp() {
        super.setUp()
        let config = try? OktaAuthConfig(with:[
            "issuer": ProcessInfo.processInfo.environment["ISSUER"]!,
            "clientId": ProcessInfo.processInfo.environment["CLIENT_ID"]!,
            "redirectUri": ProcessInfo.processInfo.environment["REDIRECT_URI"]!,
            "logoutRedirectUri": ProcessInfo.processInfo.environment["LOGOUT_REDIRECT_URI"]!,
            "scopes": "openid profile offline_access"
        ])
        oktaAppAuth = OktaAppAuth(configuration: config)
    }

    override func tearDown() {
        super.tearDown()

        // Revert stored values
        oktaAppAuth?.clear()
        oktaAppAuth = nil
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
        
        oktaAppAuth?.signOutOfOkta(from: UIViewController(), callback: { error in
            XCTAssertEqual(
                error?.localizedDescription,
                OktaError.missingIdToken.localizedDescription
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
            let response = try OktaAuthStateManager.decodeJWT(idToken)
            XCTAssertNotNil(response)
        } catch let error {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExpiredIdToken() {
        // Verify an expired token will be caught when validating
        let authStateManager = TestUtils.authStateManager()
        XCTAssertNil(authStateManager.idToken)
    }

    func testReturningTokensFromAuthStateManager() {
        // Validate that mock auth state manager returns a null token
        let authStateManager = TestUtils.authStateManager()
        self.assertAuthStateManagerContents(authStateManager)
    }

    func testReturningExpiredTokensFromAuthStateManager() {
        // Validate that mock auth state manager returns a null token
        let authStateManager = TestUtils.authStateManagerWithExpiration()
        self.assertAuthStateManagerContents(authStateManager)

        // Wait for tokens to expire and update validation options to check for expiration
        sleep(TOKEN_EXPIRATION_WAIT)

        XCTAssertEqual(oktaAppAuth?.authStateManager?.accessToken, nil)
        XCTAssertEqual(oktaAppAuth?.authStateManager?.idToken, nil)
    }

    func testStoreAndDeleteOfAuthState() {
        let authStateManager = TestUtils.authStateManager()
        oktaAppAuth?.authStateManager = authStateManager

        self.assertAuthenticationState(oktaAppAuth?.authStateManager)

        // Clear the authState
        oktaAppAuth?.authStateManager?.clear()

        XCTAssertNil(OktaAuthStateManager.readFromSecureStorage())
    }

    func testIsAuthenticated() {
        // Validate that if there is an existing accessToken, we return an "authenticated" state
        let authStateManager = TestUtils.authStateManager()
        oktaAppAuth?.authStateManager = authStateManager

        XCTAssertEqual(true, oktaAppAuth?.isAuthenticated)
    }

    func testIsNotAuthenticated() {
        // Validate that if there is an existing accessToken, we return an "authenticated" state
        let authStateManager = TestUtils.authStateManagerWithExpiration()
        oktaAppAuth?.authStateManager = authStateManager

        // Wait for tokens to expire
        sleep(TOKEN_EXPIRATION_WAIT)

        XCTAssertEqual(false, oktaAppAuth?.isAuthenticated)
    }

    func testResumeAuthenticationStateFromExpiredState() {
        // Validate that if there is an existing accessToken, we return an "authenticated" state
        let authStateManager = TestUtils.authStateManagerWithExpiration()
        oktaAppAuth?.authStateManager = authStateManager

        // Wait for tokens to expire
        sleep(TOKEN_EXPIRATION_WAIT)

        self.assertAuthenticationState(oktaAppAuth?.authStateManager)
    }

    // Helpers for asserting unit tests
    func waitForIt(_ seconds: TimeInterval = 5) {
        // XCTest Utility method to wait for expected conditions
        waitForExpectations(timeout: seconds, handler: { error in
            // Fail on timeout
            if error != nil { XCTFail(error!.localizedDescription) }
        })
    }

    func assertAuthStateManagerContents(_ tm: OktaAuthStateManager) {
        XCTAssertEqual(tm.accessToken, TestUtils.mockAccessToken)
        XCTAssertEqual(tm.refreshToken, TestUtils.mockRefreshToken)
    }

    func assertAuthenticationState(_ tm: OktaAuthStateManager?) {
        guard let prevState = OktaAuthStateManager.readFromSecureStorage() else {
            return XCTFail("Previous authentication state does not exist")
        }

        XCTAssertEqual(prevState.accessibility, tm?.accessibility)
        XCTAssertEqual(prevState.accessToken, tm?.accessToken)
        XCTAssertEqual(prevState.idToken, tm?.idToken)
        XCTAssertEqual(prevState.refreshToken, tm?.refreshToken)
    }
}
