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
import OktaAuth

class OktaUITests: XCTestCase {
    // Update these values along with your Plist config
    var username = ProcessInfo.processInfo.environment["USERNAME"]!
    var password = ProcessInfo.processInfo.environment["PASSWORD"]!
    var issuer = ProcessInfo.processInfo.environment["ISSUER"]!
    var redirectURI = ProcessInfo.processInfo.environment["REDIRECT_URI"]!
    var clientID = ProcessInfo.processInfo.environment["CLIENT_ID"]!

    var testUtils: UITestUtils!
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        
        app = XCUIApplication()
        app.launchEnvironment = ["UITEST": "1", "ISSUER": issuer, "CLIENT_ID": clientID, "REDIRECT_URI": redirectURI]
        
        testUtils = UITestUtils(app)

        continueAfterFailure = true
        app.launch()
    }

    override func tearDown() {
        super.tearDown()
    }

    func loginAndWait() {
        guard let testUtils = testUtils else { return }

        app.buttons["Login"].tap()

        // Login
        testUtils.login(username: username, password: password)

        // Wait for app to redirect back (Granting 5 second delay)
        if !testUtils.waitForElement(app.textViews["tokenView"], timeout: 5) {
            XCTFail("Unable to redirect back from browser")
        }
    }

    func testAuthCodeFlow() {
        loginAndWait()

        let tokenValues = testUtils?.getTextViewValueWithDelay(label: "tokenView", delay: 5)
        XCTAssertNotNil(tokenValues)
    }

    func testAuthCodeFlowAndUserInfo(){
        loginAndWait()

        // Get User info
        app.buttons["GetUser"].tap()

        let userInfoValue = testUtils?.getTextViewValueWithDelay(label: "tokenView", delay: 5)
        XCTAssertTrue(userInfoValue!.contains(username))
    }

    func testAuthCodeFlowIntrospectAndRevoke() {
        loginAndWait()

        // Introspect Valid Token
        app.buttons["Introspect"].tap()

        let valid = testUtils?.getTextViewValueWithDelay(label: "tokenView", delay: 5)
        XCTAssertTrue(valid!.contains("true"))
    }

    func testAuthCodeFlowRevokeAndIntrospect() {
        loginAndWait()

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
        loginAndWait()
        
        // Sign Out from Okta
        app.buttons["Sign out from Okta"].tap()

        // Wait for browser to load
        sleep(5)
        XCTAssertFalse(testUtils.isBrowserShown())
        
        app.buttons["Login"].tap()

        // If Sign Out from browser succeeded, browser should appear presenting login UI.
        // If user is still logged in in the browser, browser will appear and redirect to app automatically.
        let browserWasShown = testUtils.closeBrowserIfNeeded()
        XCTAssertTrue(browserWasShown)
        
        var tokenValues = testUtils?.getTextViewValueWithDelay(label: "tokenView", delay: 5)
        XCTAssertFalse(tokenValues?.isEmpty ?? false)
        
        // Sign Out Locally
        app.buttons["Sign out Locally"].tap()

        tokenValues = testUtils?.getTextViewValueWithDelay(label: "tokenView", delay: 5)
        XCTAssertTrue(tokenValues?.isEmpty ?? true)
    }
}
