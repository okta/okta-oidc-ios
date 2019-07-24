/*
 * Copyright (c) 2017, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import XCTest
import OktaOidc

class OktaUITests: XCTestCase {
    // Update these values along with your Plist config
    var username = ProcessInfo.processInfo.environment["USERNAME"]!
    var password = ProcessInfo.processInfo.environment["PASSWORD"]!
    var issuer = ProcessInfo.processInfo.environment["ISSUER"]!
    var redirectURI = ProcessInfo.processInfo.environment["REDIRECT_URI"]!
    var logoutRedirectURI = ProcessInfo.processInfo.environment["LOGOUT_REDIRECT_URI"]!
    var clientID = ProcessInfo.processInfo.environment["CLIENT_ID"]!

    var testUtils: UITestUtils!
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        
        app = XCUIApplication()
        app.launchEnvironment = [
            "UITEST": "1",
            "ISSUER": issuer,
            "CLIENT_ID": clientID,
            "REDIRECT_URI": redirectURI,
            "LOGOUT_REDIRECT_URI" : logoutRedirectURI
        ]
        
        testUtils = UITestUtils(app)

        continueAfterFailure = true
        app.launch()
    }

    override func tearDown() {
        super.tearDown()
    }

    func signInAndWait() {
        guard let testUtils = testUtils else { return }

        guard testUtils.waitForElement(app.textViews["tokenView"], timeout: 5.0) else {
            XCTFail("Cannot start the app!")
            return
        }

        app.buttons["SignIn"].tap()

        // Sign In
        testUtils.signIn(username: username, password: password)

        // Wait for app to redirect back (Granting 5 second delay)
        guard let _ = testUtils.getTextViewValueWithDelay(label: "tokenView", delay: 5) else {
            XCTFail("Unable to redirect back from browser")
            return
        }
    }

    func testAuthCodeFlow() {
        signInAndWait()
        
        var tokenValues = testUtils?.getTextViewValueWithDelay(label: "tokenView", delay: 5)
        XCTAssertNotNil(tokenValues)
        XCTAssertNotEqual(tokenValues, "")

        app.terminate()
        app.launch()
        
        tokenValues = testUtils?.getTextViewValueWithDelay(label: "tokenView", delay: 1)
        XCTAssertNotNil(tokenValues)
        XCTAssertNotEqual(tokenValues, "")
    }

    func testAuthCodeFlowAndUserInfo(){
        signInAndWait()

        // Get User info
        app.buttons["GetUser"].tap()

        let userInfoValue = testUtils?.getTextViewValueWithDelay(label: "tokenView", delay: 5)
        XCTAssertTrue(userInfoValue!.contains(username))
    }

    func testAuthCodeFlowIntrospectAndRevoke() {
        signInAndWait()

        // Introspect Valid Token
        app.buttons["Introspect"].tap()

        let valid = testUtils?.getTextViewValueWithDelay(label: "tokenView", delay: 5)
        XCTAssertTrue(valid!.contains("true"))
    }

    func testAuthCodeFlowRevokeAndIntrospect() {
        signInAndWait()

        // Revoke Token
        app.buttons["Revoke"].tap()

        let revoked = testUtils?.getTextViewValueWithDelay(label: "tokenView", delay: 5)
        XCTAssertTrue(revoked!.contains("AccessToken was revoked"))

        // Introspect invalid Token
        app.buttons["Introspect"].tap()

        let isNotValid = testUtils?.getTextViewValueWithDelay(label: "tokenView", delay: 5)
        XCTAssertTrue(isNotValid!.contains("false"))

        // Clear all tokens
        app.buttons["Clear"].tap()
    }
	
    func testSignOutFlow() {
        signInAndWait()
        
        // Sign Out from Okta
        app.buttons["SignOutOkta"].tap()
        
        // Wait for browser to load
        // This sleep bypasses the need to "click" the consent for Safari
        sleep(5)

        // Known bug with iOS 11 and system alerts
        app.tap()
		
        // Wait for browser to dismiss
        guard let _ = testUtils?.getTextViewValueWithDelay(label: "tokenView", delay: 5) else {
            XCTFail("Should return to main screen!")
            return
        }

        // Sign In to Okta
        app.buttons["SignIn"].tap()
        
        // Wait for browser to load
        // This sleep bypasses the need to "click" the consent for Safari
        sleep(5)

        // Known bug with iOS 11 and system alerts
        app.tap()
        
        // Broweser should appear for user who is not signed in
        guard testUtils.waitForElement(app.webViews.firstMatch, timeout: 5.0) else {
            XCTFail("Broweser should be loaded!")
            return
        }
    }
    
    func testAuthenticateWithSessionToken() {
        app.buttons["Authenticate"].tap()
        
        guard testUtils.waitForElement(app.textViews["TokenTextView"], timeout: 5) else {
            XCTFail("Should redirect to authentication screen.")
            return
        }
        
        let tokenView = app.textViews["TokenTextView"]
        
        tokenView.tap()
        tokenView.typeText("Some_Invalid_Token")

        let button = app.buttons.element(matching: .button, identifier: "AuthenticateWithSessionToken")
        guard button.exists else {
            XCTFail("Can't find authenticate button")
            return
        }

        button.tap()
        
        guard let errorDescription = testUtils.getTextViewValueWithDelay(label: "MessageView", delay: 5) else {
            XCTFail("Authentication with invalid token should fail.")
            return
        }
        
        XCTAssertTrue(errorDescription.contains("Error"))
    }
}
