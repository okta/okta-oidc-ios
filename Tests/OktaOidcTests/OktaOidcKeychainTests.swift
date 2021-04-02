/*
 * Copyright (c) 2019-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

@testable import OktaOidc
import XCTest

#if !SWIFT_PACKAGE || !os(iOS)

class OktaKeychainTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        
        OktaOidcKeychain.clearAll()
    }

    func testStringStorage() {
        let key = "test_key"
        let value = "test_value"

        do {
            try OktaOidcKeychain.set(key: key, string: value);

            let readValue: String = try OktaOidcKeychain.get(key: key)

            XCTAssertEqual(value, readValue);
        } catch let e {
            XCTFail(e.localizedDescription)
        }
    }

    func testDataStorage() {
        let key = "test_key"
        let value = "test_value".data(using: .utf8)!

        do {
            try OktaOidcKeychain.set(key: key, data: value)

            let readValue: Data = try OktaOidcKeychain.get(key: key)

            XCTAssertEqual(value, readValue)
        } catch let e {
            XCTFail(e.localizedDescription)
        }
    }
    
    func testReadFailure() {
        let key = "unknown_key"
        
        do {
            let _: String = try OktaOidcKeychain.get(key: key)
            
        } catch OktaOidcKeychainError.notFound {
            XCTAssertTrue(true)
            
        } catch let e {
            XCTFail(e.localizedDescription)
        }
    }

    func testRemove() {
        let key = "test_key"
        let value = "test_value"

        do {
            try OktaOidcKeychain.set(key: key, string: value)

            try OktaOidcKeychain.remove(key: key)

            let _: String = try OktaOidcKeychain.get(key: key)

        } catch OktaOidcKeychainError.notFound {
            XCTAssertTrue(true)

        } catch let e {
            XCTFail(e.localizedDescription)
        }
    }
    
    func testRemoveFailure() {
        let key = "unknown_key"
        
        do {
            try OktaOidcKeychain.remove(key: key)
            
        } catch OktaOidcKeychainError.notFound {
            XCTAssertTrue(true)
            
        } catch let e {
            XCTFail(e.localizedDescription)
        }
    }

    func testClearAll() {
        let key1 = "test_key_1"
        let key2 = "test_key_2"
        let value = "test_value"

        do {
            try OktaOidcKeychain.set(key: key1, string: value)
            try OktaOidcKeychain.set(key: key2, string: value)

            OktaOidcKeychain.clearAll()

            let _: String = try OktaOidcKeychain.get(key: key1)
            let _: String = try OktaOidcKeychain.get(key: key2)

        } catch OktaOidcKeychainError.notFound {
            XCTAssertTrue(true)

        } catch let e {
            XCTFail(e.localizedDescription)
        }
    }
}

#endif
