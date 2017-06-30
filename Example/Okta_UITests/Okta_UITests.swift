//
//  Okta_UITests.swift
//  Okta_UITests
//
//  Created by Jordan Melberg on 6/21/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest
import OktaAuth

class OktaUITests: XCTestCase {
    var username, password: String?

    override func setUp() {
        super.setUp()

        // Update these values along with your Plist config
        username = "{username}"
        password = "{password}"

        continueAfterFailure = false
        XCUIApplication().launch()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testAuthorizationCodeFlow() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.

        let app = XCUIApplication()

        app.buttons["Login"].tap()

        // Wait for browser to load
        sleep(2)

        let webViewsQuery = app.webViews
        webViewsQuery.textFields["Username"].tap()
        webViewsQuery.textFields["Username"].typeText("johndoe")
        webViewsQuery.secureTextFields["Password"].tap()
        webViewsQuery.secureTextFields["Password"].typeText("password")

        app
            .children(matching: .window)
            .element(boundBy: 0)
            .children(matching: .other)
            .element
            .children(matching: .other)
            .element(boundBy: 0)
            .tap()

        // Wait for app to redirect back (Granting 3 second delay)
        sleep(2)

        if let tokenValues = app.textViews["tokenView"].value as? String {
            XCTAssertNotNil(tokenValues)
        } else {
            // Fail test
            XCTAssertTrue(false)
        }

        // Refresh tokens
        var oldTokens = app.textViews["tokenView"].value as? String

        if oldTokens != nil {
            oldTokens = oldTokens!
        }

        // Double tap to call twice
        app.buttons["Refresh Tokens"].tap()
        app.buttons["Refresh Tokens"].tap()

        sleep(2)
        if let tokenCheck = app.textViews["tokenView"].value as? String {
            XCTAssertNotEqual(oldTokens, tokenCheck)
        }

        // Get User info
        app.buttons["Userinfo"].tap()
        if let userInfoValue = app.textViews["tokenView"].value as? String {
            XCTAssertTrue(userInfoValue.contains("johndoe"))
        } else {
            // Fail test
            XCTAssertTrue(false)
        }

        // Introspect Valid Token
        app.buttons["Introspect"].tap()
        if let valid = app.textViews["tokenView"].value as? String {
            XCTAssertTrue(valid.contains("true"))
        } else {
            // Fail test
            XCTAssertTrue(false)
        }

        // Revoke Token
        app.buttons["Revoke"].tap()
        if let revoked = app.textViews["tokenView"].value as? String {
            XCTAssertTrue(revoked.contains("AccessToken was revoked"))
        } else {
            // Fail test
            XCTAssertTrue(false)
        }

        // Introspect invalid Token
        app.buttons["Introspect"].tap()
        if let isNotValid = app.textViews["tokenView"].value as? String {
            XCTAssertTrue(isNotValid.contains("false"))
        } else {
            // Fail test
            XCTAssertTrue(false)
        }

        // Clear Tokens
        app.buttons["Clear"].tap()
        if let val = app.textViews["tokenView"].value as? String {
            XCTAssertEqual("", val)
        }
    }
}
