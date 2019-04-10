//
//  OktaKeychainTests.swift
//  Okta_Example
//
//  Created by Alex on 20 Feb 19.
//  Copyright © 2019 Okta. All rights reserved.
//

import XCTest
@testable import OktaOidc

class OktaKeychainTests : XCTestCase {

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
