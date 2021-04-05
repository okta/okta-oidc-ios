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

import XCTest

extension XCUIElement {
    
    @objc var stringValue: String? {
        value as? String
    }
    
    func clearText(app: XCUIApplication? = nil) {
        guard let stringValue = value as? String else {
            XCTFail("Tried to clear and enter text into a non string value.")
            return
        }
        
        if stringValue.isEmpty || stringValue == placeholderValue {
            return
        }
        
        if let app = app {
            press(forDuration: 1.3)
            
            let selectAllMenuItem = app.menuItems["Select All"]
            
            if selectAllMenuItem.waitForExistence(timeout: .minimal) {
                selectAllMenuItem.tap()
            }
            
            let cutMenuItem = app.menuItems["Cut"]
            if cutMenuItem.waitForExistence(timeout: .minimal) {
                cutMenuItem.tap()
            }
        }
        
        for deletedChar in String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count) {
            typeText(String(deletedChar))
        }
    }
}
