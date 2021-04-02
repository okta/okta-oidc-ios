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

public struct UITestUtils {
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    var testApp: XCUIApplication

    init(_ app: XCUIApplication) {
        testApp = app
    }

    func allowBrowserLaunch() {
        let allowButton = springboard.buttons["Continue"]
        if allowButton.waitForExistence(timeout: 5) {
            allowButton.tap()
        } else {
            XCTFail("Expected system alert to appear!")
        }
    }

    func findPasswordField(app: XCUIApplication, usernameFieldFrame: CGRect) -> XCUIElement? {
        let secureTextFields = app.webViews.secureTextFields
        guard secureTextFields.count > 0 else {
            return nil
        }

        if secureTextFields.count == 1 {
            return secureTextFields.firstMatch
        }

        // SIW may contain 3 instances of secure text fields: 2 invisible and the password text field.
        // As neither of those fields has identifier, and all of them are reported as enabled and hittable,
        // detect password field as the one which is at least as wide as the username field
        for index in 0...secureTextFields.count {
            let textField = secureTextFields.element(boundBy: index)
            guard textField.isHittable else {
                continue
            }

            let textFieldFrame = textField.frame
            if (textFieldFrame.size.width >= usernameFieldFrame.size.width) {
                return textField
            }
        }
        return nil
    }

    func signIn(username: String, password: String) {
        allowBrowserLaunch()

        let webViewsQuery = testApp.webViews
        let uiElementUsername = webViewsQuery.textFields.element(boundBy: 0)
        XCTAssertTrue(uiElementUsername.waitForExistence(timeout: 60))
        let usernameFrame = uiElementUsername.frame

        uiElementUsername.tap()
        uiElementUsername.typeText(username)

        // If the "Swipe-to-type" keyboard is shown (e.g. this is the first launch of the
        // device after an Erase & Restart), dismiss the keyboard onboarding view to reveal
        // the regular software keyboard.
        let continueButton = testApp.buttons["Continue"]
        if continueButton.exists {
            continueButton.tap()
        }

        let nextButton = testApp.toolbars["Toolbar"].buttons["Next"]
        if nextButton.exists {
            nextButton.tap()
        }

        let uiElementPasswordDetectExistence = webViewsQuery.secureTextFields.element(boundBy: 0)

        XCTAssertTrue(uiElementPasswordDetectExistence.waitForExistence(timeout: 60))

        guard let uiElementPassword = findPasswordField(app: testApp, usernameFieldFrame: usernameFrame) else {
            XCTFail("Unable to detect password text field")
            return
        }

        uiElementPassword.tap()
        uiElementPassword.typeText(password)
        
        // Dismiss the keyboard to prevent the keyboard from intercepting the tap inadvertently
        // when the "Sign In" button is tapped.
        let doneButton = testApp.toolbars["Toolbar"].buttons["Done"]
        if doneButton.exists {
            doneButton.tap()
        }

        if webViewsQuery.buttons["Verify"].exists {
            webViewsQuery.buttons["Verify"].firstMatch.tap()
        } else {
            webViewsQuery.buttons["Sign In"].firstMatch.tap()
        }
    }

    func getTextViewValue(label: String) -> String? {
        // Returns the value of a textView
        if let value = testApp.textViews[label].value as? String {
            return value
        }
        return nil
    }

    func getTextViewValueWithDelay(label: String, delay: UInt32) -> String? {
        // Returns the value of a textView after a given delay
        sleep(delay)
        return getTextViewValue(label: label)
    }

    func waitForElement(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        // Generic wait for element to apepar function w/ timeout
        let pred = NSPredicate(format: "exists == true")
        let testcase = XCTestCase()
        let exp = testcase.expectation(for: pred, evaluatedWith: element, handler: nil)
        let result = XCTWaiter.wait(for: [exp], timeout: timeout)
        return result == .completed
    }
}
