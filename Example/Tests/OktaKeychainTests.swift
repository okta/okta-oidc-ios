//
//  OktaKeychainTests.swift
//  Okta_Example
//
//  Created by Alex on 20 Feb 19.
//  Copyright © 2019 Okta. All rights reserved.
//

import XCTest
@testable import OktaAuth

class OktaKeychainTests : XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        OktaKeychain.clearAll()
    }

    func testStringStorage() {
        let key = "test_key"
        let value = "test_value"

        do {
            try OktaKeychain.set(key: key, string: value);

            let readValue: String = try OktaKeychain.get(key: key)

            XCTAssertEqual(value, readValue);
        } catch let e {
            XCTFail(e.localizedDescription)
        }
    }

    func testDataStorage() {
        let key = "test_key"
        let value = "test_value".data(using: .utf8)!

        do {
            try OktaKeychain.set(key: key, data: value)

            let readValue: Data = try OktaKeychain.get(key: key)

            XCTAssertEqual(value, readValue)
        } catch let e {
            XCTFail(e.localizedDescription)
        }
    }
    
    func testReadFailure() {
        let key = "unknown_key"
        
        do {
            let _: String = try OktaKeychain.get(key: key)
            
        } catch OktaKeychainError.notFound {
            XCTAssertTrue(true)
            
        } catch let e {
            XCTFail(e.localizedDescription)
        }
    }

    func testRemove() {
        let key = "test_key"
        let value = "test_value"

        do {
            try OktaKeychain.set(key: key, string: value)

            try OktaKeychain.remove(key: key)

            let _: String = try OktaKeychain.get(key: key)

        } catch OktaKeychainError.notFound {
            XCTAssertTrue(true)

        } catch let e {
            XCTFail(e.localizedDescription)
        }
    }
    
    func testRemoveFailure() {
        let key = "unknown_key"
        
        do {
            try OktaKeychain.remove(key: key)
            
        } catch OktaKeychainError.notFound {
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
            try OktaKeychain.set(key: key1, string: value)
            try OktaKeychain.set(key: key2, string: value)

            OktaKeychain.clearAll()

            let _: String = try OktaKeychain.get(key: key1)
            let _: String = try OktaKeychain.get(key: key2)

        } catch OktaKeychainError.notFound {
            XCTAssertTrue(true)

        } catch let e {
            XCTFail(e.localizedDescription)
        }
    }
}
