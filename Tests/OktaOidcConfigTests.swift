/*
 * Copyright (c) 2019, Okta, Inc. and/or its affiliates. All rights reserved.
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
@testable import OktaOidc

class OktaOidcConfigTests: XCTestCase {
    
    func testCreation() {
        let dict = [
            "clientId" : "test_client_id",
            "issuer" : "test_issuer",
            "scopes" : "test_scope",
            "redirectUri" : "com.test:/callback",
            "logoutRedirectUri" : "com.test:/logout"
        ]
        
        let config: OktaOidcConfig
        do {
            config = try OktaOidcConfig(with: dict)
        } catch let error {
            XCTFail("Unexpected error: \(error)")
            return
        }
        
        XCTAssertEqual("test_client_id", config.clientId)
        XCTAssertEqual("test_issuer", config.issuer)
        XCTAssertEqual("test_scope", config.scopes)
        XCTAssertEqual(URL(string: "com.test:/callback"), config.redirectUri)
        XCTAssertEqual(URL(string: "com.test:/logout"), config.logoutRedirectUri)
        XCTAssertEqual(true, config.additionalParams?.isEmpty)
    }
    
    func testCreationWithAdditionalParams() {
        let dict = [
            "clientId" : "test_client_id",
            "issuer" : "test_issuer",
            "scopes" : "test_scope",
            "redirectUri" : "com.test:/callback",
            "logoutRedirectUri" : "com.test:/logout",
            "additionalParam" : "test_param",
        ]
        
        let config: OktaOidcConfig
        do {
            config = try OktaOidcConfig(with: dict)
        } catch let error {
            XCTFail("Unexpected error: \(error)")
            return
        }
        
        XCTAssertEqual("test_client_id", config.clientId)
        XCTAssertEqual("test_issuer", config.issuer)
        XCTAssertEqual("test_scope", config.scopes)
        XCTAssertEqual(URL(string: "com.test:/callback"), config.redirectUri)
        XCTAssertEqual(URL(string: "com.test:/logout"), config.logoutRedirectUri)

        XCTAssertEqual(1, config.additionalParams?.count)
        XCTAssertEqual("test_param", config.additionalParams?["additionalParam"])
    }

    func testCreationWithInvalidConfig() {
        var dict = [
            "clientId" : "test_client_id",
            "issuer" : "",
            "scopes" : "test_scope",
            "redirectUri" : "com.test:/callback"
        ]

        do {
            let _ = try OktaOidcConfig(with: dict)
        } catch let error {
            XCTAssertTrue(error.localizedDescription == OktaOidcError.missingConfigurationValues.errorDescription)
            return
        }

        dict = [
            "clientId" : "",
            "issuer" : "http://www.test.com",
            "scopes" : "test_scope",
            "redirectUri" : "com.test:/callback"
        ]
        
        do {
            let _ = try OktaOidcConfig(with: dict)
        } catch let error {
            XCTAssertTrue(error.localizedDescription == OktaOidcError.missingConfigurationValues.errorDescription)
            return
        }

        dict = [
            "clientId" : "test_client_id",
            "issuer" : "http://www.test.com",
            "scopes" : "test_scope",
            "redirectUri" : ""
        ]
        
        do {
            let _ = try OktaOidcConfig(with: dict)
        } catch let error {
            XCTAssertTrue(error.localizedDescription == OktaOidcError.missingConfigurationValues.errorDescription)
            return
        }
    }
    
    func testDefaultConfig() {
        do {
            let _ = try OktaOidcConfig.default()
        } catch let error {
            XCTAssertEqual(
                OktaOidcError.missingConfigurationValues.localizedDescription,
                error.localizedDescription
            )
        }
    }
    
    func testOktaPlist() {
        do {
            let _ = try OktaOidcConfig(fromPlist: "Okta")
        } catch let error {
            XCTAssertEqual(
                OktaOidcError.missingConfigurationValues.localizedDescription,
                error.localizedDescription
            )
        }
    }
    
    func testNoPListGiven() {
        // name of file which does not exists
        let plistName = UUID().uuidString
        var config: OktaOidcConfig? = nil
        do {
           config = try OktaOidcConfig(fromPlist: plistName)
        } catch let error {
            XCTAssertEqual(
                error.localizedDescription,
                OktaOidcError.noPListGiven.localizedDescription
            )
        }
        
        XCTAssertNil(config)
    }
    
    func testPListParseFailure() {
        // Info.plist does not correspond to expected structure of Okta file
        let plistName = "Info"
        var config: OktaOidcConfig? = nil
        do {
            config = try OktaOidcConfig(fromPlist: plistName)
        } catch let error {
            XCTAssertEqual(
                error.localizedDescription,
                OktaOidcError.pListParseFailure.localizedDescription
            )
        }
        
        XCTAssertNil(config)
    }
}
