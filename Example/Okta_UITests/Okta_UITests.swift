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
    var username = "{username}"
    var password = "{password}"

    var testUtils: UITestUtils?
    let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        testUtils = UITestUtils(app)

        continueAfterFailure = false
        XCUIApplication().launch()
    }

    override func tearDown() {
        super.tearDown()
    }

    func loginAndWait() {
        guard let testUtils = testUtils else { return }

        // Check to see if there are tokens displayed (indicating an authenticated state)
        if let tokens = testUtils.getTextViewValue(label: "tokenView"), tokens.contains("Access Token") {
            return
        }

        app.buttons["Login"].tap()

        // Wait for browser to load
        // This sleep bypasses the need to "click" the consent for Safari
        sleep(2)

        // Login
        testUtils.login(username: username, password: password)

        // Wait for app to redirect back (Granting 5 second delay)
        if !testUtils.waitForElement(app.textViews["tokenView"], timeout: 5) {
            XCTFail("Unable to redirect back from browser")
        }
    }

    func testAuthCodeFlow() {
        loginAndWait()

        let tokenValues = testUtils?.getTextViewValue(label: "tokenView")
        XCTAssertNotNil(tokenValues)
    }

    func testAuthCodeFlowAndUserInfo(){
        loginAndWait()

        // Get User info
        app.buttons["GetUser"].tap()

        let userInfoValue = testUtils?.getTextViewValueWithDelay(label: "tokenView", delay: 2)
        XCTAssertTrue(userInfoValue!.contains(username))
    }

    func testAuthCodeFlowIntrospectAndRevoke() {
        loginAndWait()

        // Introspect Valid Token
        app.buttons["Introspect"].tap()

        let valid = testUtils?.getTextViewValueWithDelay(label: "tokenView", delay: 2)
        XCTAssertTrue(valid!.contains("true"))

        // Revoke Token
        app.buttons["Revoke"].tap()

        let revoked = testUtils?.getTextViewValue(label: "tokenView")
        XCTAssertTrue(revoked!.contains("AccessToken was revoked"))

        // Introspect invalid Token
        app.buttons["Introspect"].tap()

        let isNotValid = testUtils?.getTextViewValue(label: "tokenView")
        XCTAssertTrue(isNotValid!.contains("false"))

        // Clear all tokens
        app.buttons["Clear"].tap()
    }
}
