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
    var username = ""
    var password = ""

    override func setUp() {
        super.setUp()

        // Update these values along with your Plist config
        username = "{username}"
        password = "{password}"

        continueAfterFailure = false
        XCUIApplication().launch()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testAuthorizationCodeFlow() {
        let app = XCUIApplication()
        let testUtils = UITestUtils(app)

        app.buttons["Login"].tap()

        // Wait for browser to load
        // This sleep bypasses the need to "click" the consent for Safari
        sleep(2)

        // Login
        testUtils.login(username: username, password: password)

        // Wait for app to redirect back (Granting 3 second delay)
        if !testUtils.waitForElement(app.textViews["tokenView"], timeout: 3) {
            XCTFail("Unable to redirect back from browser")
        }

        let tokenValues = testUtils.getTextViewValue(label: "tokenView")
        XCTAssertNotNil(tokenValues)

        // Refresh tokens

        // Double tap to call twice
        app.buttons["Refresh Tokens"].tap()
        app.buttons["Refresh Tokens"].tap()

        let newTokens = testUtils.getTextViewValue(label: "tokenView")
        XCTAssertNotNil(newTokens)

        // Validate tokens have been updated
        XCTAssertNotEqual(tokenValues!, newTokens!)

        // Get User info
        app.buttons["Userinfo"].tap()

        let userInfoValue = testUtils.getTextViewValue(label: "tokenView")
        XCTAssertTrue(userInfoValue!.contains(username))

        // Introspect Valid Token
        app.buttons["Introspect"].tap()

        let valid = testUtils.getTextViewValue(label: "tokenView")
        XCTAssertTrue(valid!.contains("true"))

        // Revoke Token
        app.buttons["Revoke"].tap()

        let revoked = testUtils.getTextViewValue(label: "tokenView")
        XCTAssertTrue(revoked!.contains("AccessToken was revoked"))

        // Introspect invalid Token
        app.buttons["Introspect"].tap()

        let isNotValid = testUtils.getTextViewValue(label: "tokenView")
        XCTAssertTrue(isNotValid!.contains("false"))

        // Clear Tokens
        app.buttons["Clear"].tap()

        let val = testUtils.getTextViewValue(label: "tokenView")
        XCTAssertEqual(val!, "")
    }
}
