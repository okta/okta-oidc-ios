//
//  Okta_UITests.swift
//  Okta_UITests
//
//  Created by Jordan Melberg on 6/21/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest
import OktaAuth

class Okta_UITests: XCTestCase {
    var username, password: String?
    
    override func setUp() {
        super.setUp()
        
        username = "johndoe"
        password = "password"
        
        continueAfterFailure = false
        XCUIApplication().launch()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let app = XCUIApplication()
        
        // Wait for browser to load
        sleep(2)
        
        let webViewsQuery = app.webViews
        webViewsQuery.textFields["Username"].tap()
        webViewsQuery.textFields["Username"].typeText("johndoe")
        webViewsQuery.secureTextFields["Password"].tap()
        webViewsQuery.secureTextFields["Password"].typeText("password")
        
        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element(boundBy: 0).tap()
        
        // Wait for app to redirect back (Granting 3 second delay)
        sleep(2)
        let textView = app.textViews["tokenView"]
        
        if let tokenValues = textView.value as? String {
            XCTAssertNotNil(tokenValues)
        } else {
            // Fail test
            XCTAssertTrue(false)
        }
    }
}

