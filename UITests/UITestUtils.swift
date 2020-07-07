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
    var testApp: XCUIApplication
    init(_ app: XCUIApplication) {
        testApp = app
    }

    func signIn(username: String, password: String) {
        // Wait for browser to load
        // This sleep bypasses the need to "click" the consent for Safari
        sleep(5)

        // Known bug with iOS 11 and system alerts
        testApp.tap()

        // Sign In via username and password inside of the Safari WebView
        let webViewsQuery = testApp.webViews
        let uiElementUsername = webViewsQuery.textFields.element(boundBy: 0)
        XCTAssertTrue(uiElementUsername.waitForExistence(timeout: 20))
        uiElementUsername.tap()
        uiElementUsername.typeText(username)
        if webViewsQuery.buttons["Next"].exists {
            webViewsQuery.buttons["Next"].tap()
        }
        enterPassword(password, in: webViewsQuery)
        if webViewsQuery.buttons["Sign In"].exists {
            webViewsQuery.buttons["Sign In"].tap()
        } else if webViewsQuery.buttons["Verify"].exists {
            webViewsQuery.buttons["Verify"].tap()
        }

        XCTAssertTrue(webViewsQuery.buttons["Verify"].waitForExistence(timeout: 20))
        enterPassword("okta", in: webViewsQuery)
        webViewsQuery.buttons["Verify"].tap()
    }

    func enterPassword(_ password: String, in element: XCUIElementQuery) {
        var passwordTextField: XCUIElement?
        if element.secureTextFields.count > 1 {
            var currentTextFieldWidth: CGFloat = 0.0
            for i in 0...(element.secureTextFields.count-1) {
                let textField = element.secureTextFields.element(boundBy: i)
                if textField.frame.width > currentTextFieldWidth {
                    passwordTextField = textField
                    currentTextFieldWidth = textField.frame.width
                }
            }
        } else {
            passwordTextField = element.secureTextFields.element(boundBy: 0)
        }

        if let passwordTextField = passwordTextField {
            XCTAssertTrue(passwordTextField.waitForExistence(timeout: 60))
            passwordTextField.tap()
            sleep(1)
            passwordTextField.typeText(password)
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
