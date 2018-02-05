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

    func login(username: String, password: String) {
        // Login via username and password inside of the Safari WebView
        let webViewsQuery = testApp.webViews
        let usernameField = webViewsQuery.textFields["Username"]
        let passwordField = webViewsQuery.secureTextFields["Password"]

        usernameField.tap()
        usernameField.typeText(username)
        passwordField.tap()
        passwordField.typeText(password)
        webViewsQuery.buttons["Sign In"].tap()
    }

    func getTextViewValue(label: String) -> String? {
        // Returns the value of a textView
        if let value = testApp.textViews[label].value as? String {
            return value
        }
        return nil
    }

    func waitForElement(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        // Generic wait for element to apepar function w/ timeout
        let pred = NSPredicate(format: "exists == true")
        let exp = XCTestCase().expectation(for: pred, evaluatedWith: element, handler: nil)
        let result = XCTWaiter.wait(for: [exp], timeout: timeout)
        return result == .completed
    }
}
