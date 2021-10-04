/*
 * Copyright (c) 2017-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

// swiftlint:disable force_try
// swiftlint:disable force_cast
// swiftlint:disable force_unwrapping

import OktaOidc
import XCTest

final class OktaScenarios: XCTestCase {
    // Update these values along with your Plist config
    var username = ProcessInfo.processInfo.environment["USERNAME"]!
    var password = ProcessInfo.processInfo.environment["PASSWORD"]!
    var issuer = ProcessInfo.processInfo.environment["ISSUER"]!
    var redirectURI = ProcessInfo.processInfo.environment["REDIRECT_URI"]!
    var logoutRedirectURI = ProcessInfo.processInfo.environment["LOGOUT_REDIRECT_URI"]!
    var clientID = ProcessInfo.processInfo.environment["CLIENT_ID"]!
    
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    
    private var browserContinueButton: XCUIElement {
        springboard.buttons["Continue"]
    }
    
    private var toolbarDoneButton: XCUIElement {
        app.toolbars["Toolbar"].buttons["Done"]
    }
    
    private var app: XCUIApplication!
    
    private var tokenTextView: XCUIElement {
        app.textViews["tokenView"]
    }
    
    private var signInButton: XCUIElement {
        app.buttons["SignIn"]
    }
    
    private var sessionTokenTextView: XCUIElement {
        app.textViews["SessionTokenTextView"]
    }
    
    private var getUserButton: XCUIElement {
        app.buttons["GetUser"]
    }
    
    private var introspectButton: XCUIElement {
        app.buttons["Introspect"]
    }
    
    private var revokeButton: XCUIElement {
        app.buttons["Revoke"]
    }
    
    private var clearButton: XCUIElement {
        app.buttons["Clear"]
    }
    
    private var signOutButton: XCUIElement {
        app.buttons["SignOutOkta"]
    }
    
    private var continueSpringboardButton: XCUIElement {
        springboard.buttons["Continue"]
    }
    
    private var authenticateButton: XCUIElement {
        app.buttons["Authenticate"]
    }
    
    // MARK: -
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        try XCTSkipIf(clientID.isEmpty || password.isEmpty,
                      "Cannot run UI tests without CLIENT_ID or PASSWORD environment variables")
        
        app = XCUIApplication()
        app.launchEnvironment = [
            "UITEST": "1",
            "ISSUER": issuer,
            "CLIENT_ID": clientID,
            "REDIRECT_URI": redirectURI,
            "LOGOUT_REDIRECT_URI": logoutRedirectURI
        ]
        
        continueAfterFailure = false
        app.launch()
        
        if clearButton.exists {
            clearButton.tap()
        }
    }
    
    func testAuthCodeFlow() {
        // given
        signInAndWait()
    
        waitForText(predicate: "CONTAINS 'Access Token'", object: tokenTextView, timeout: .testing)
        
        // when
        app.terminate()
        app.launch()
        // then
        waitForText(predicate: "CONTAINS 'Access Token'", object: tokenTextView, timeout: .testing)

        // then
        pressGetUserButton()
        pressIntrospectButton(expectedValue: "true")
        pressRevokeButton()
        
        signOut()
    }
    
    func testAuthCodeFlowAndUserInfo() throws {
        // given
        signInAndWait()
        // then
        pressGetUserButton()
        
        signOut()
    }
    
    func testAuthCodeFlowIntrospectAndRevoke() throws {
        // given
        signInAndWait()
        // then
        pressIntrospectButton(expectedValue: "true")
        
        signOut()
    }
    
    func testAuthCodeFlowRevokeAndIntrospect() throws {
        // given
        signInAndWait()
        // then
        pressRevokeButton()
        pressIntrospectButton(expectedValue: "false")
        
        signOut()
    }
    
    func testAuthenticateWithInvalidSessionToken() throws {
        // given
        authenticateButton.tap()
        XCTAssertTrue(sessionTokenTextView.waitForExistence(timeout: .minimal))
        
        sessionTokenTextView.clearText(app: app)
        sessionTokenTextView.tap()
        sessionTokenTextView.typeText("Some_Invalid_Token")
        
        // when
        let authbutton = app.buttons["AuthenticateWithSessionToken"]
        authbutton.tap()
        
        // then
        let messageView = app.textViews["MessageView"]
        XCTAssertTrue(messageView.waitForExistence(timeout: .testing))
        
        waitForText(predicate: "CONTAINS 'Error'", object: messageView, timeout: .minimal)
    }
    
    // MARK: - Private
    
    private func signInAndWait() {
        XCTAssertTrue(tokenTextView.waitForExistence(timeout: .minimal))
        XCTAssertNotEqual(tokenTextView.value as? String, "SDK is not configured!")
        
        // Sign In
        signIn(username: username, password: password)
        
        XCTAssertTrue(tokenTextView.waitForExistence(timeout: .minimal))
    }
    
    private func pressGetUserButton() {
        getUserButton.tap()
        // then
        waitForText(predicate: "CONTAINS '\(username)'", object: tokenTextView, timeout: .testing)
    }
    
    private func pressIntrospectButton(expectedValue: String) {
        introspectButton.tap()
        // then
        waitForText(predicate: "CONTAINS '\(expectedValue)'", object: tokenTextView, timeout: .testing)
    }
    
    private func pressRevokeButton() {
        // when
        revokeButton.tap()
        // then
        waitForText(predicate: "CONTAINS 'AccessToken was revoked'", object: tokenTextView, timeout: .testing)
    }
    
    private func signIn(username: String, password: String) {
        signInButton.tap()
        
        allowBrowserLaunch()
        
        let webView = app.webViews
        let usernameWebField = webView.textFields.element(boundBy: 0)
        
        XCTAssertTrue(usernameWebField.waitForExistence(timeout: .testing))
        usernameWebField.tap()
        
        // If the "Swipe-to-type" keyboard is shown (e.g. this is the first launch of the
        // device after an Erase & Restart), dismiss the keyboard onboarding view to reveal
        // the regular software keyboard.
        let continueButton = app.buttons["Continue"]
        if continueButton.exists {
            continueButton.tap()
        }
        
        usernameWebField.clearText(app: app)
        usernameWebField.typeText(username)
        
        if toolbarDoneButton.exists {
            toolbarDoneButton.tap()
        }
        
        let passwordWebField = webView.secureTextFields.allElementsBoundByIndex.first { $0.frame.width >= usernameWebField.frame.width }!
        
        XCTAssertTrue(passwordWebField.waitForExistence(timeout: .testing))
        
        passwordWebField.tap()
        UIPasteboard.general.string = password
        passwordWebField.doubleTap()
        app.menuItems["Paste"].tap()
        
        // We would dismiss keyboard by entering return key ('\n').
        // But there's 'Go' button instead of return.
        if toolbarDoneButton.exists {
            toolbarDoneButton.tap()
        }
        
        let verifyWebButton = webView.buttons["Verify"]
        
        if verifyWebButton.exists {
            verifyWebButton.tap()
        } else {
            webView.buttons["Sign In"].tap()
        }
    }
    
    private func signOut() {
        signOutButton.tap()
        
        // then
        XCTAssertTrue(continueSpringboardButton.waitForExistence(timeout: .minimal))
        continueSpringboardButton.tap()
        
        // Allows the browser open and close immediately.
        sleep(5)
        
        XCTAssertTrue(tokenTextView.waitForExistence(timeout: .testing))
        
        waitForText(predicate: "== ''", object: tokenTextView, timeout: .minimal)
    }
  
    private func allowBrowserLaunch() {
        XCTAssertTrue(browserContinueButton.waitForExistence(timeout: .minimal))
        browserContinueButton.tap()
    }
}

extension TimeInterval {
    
    static let testing: TimeInterval = 30
    static let minimal: TimeInterval = testing / 2
}
