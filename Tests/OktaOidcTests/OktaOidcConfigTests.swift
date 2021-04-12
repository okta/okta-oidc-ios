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

#if SWIFT_PACKAGE
@testable import TestCommon
#endif

class OktaOidcConfigTests: XCTestCase {
    
    func testCreation() {
        let dict = [
            "clientId": "test_client_id",
            "issuer": "test_issuer",
            "scopes": "test_scope",
            "redirectUri": "com.test:/callback",
            "logoutRedirectUri": "com.test:/logout"
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
            "clientId": "test_client_id",
            "issuer": "test_issuer",
            "scopes": "test_scope",
            "redirectUri": "com.test:/callback",
            "logoutRedirectUri": "com.test:/logout",
            "additionalParam": "test_param",
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
            "clientId": "test_client_id",
            "issuer": "",
            "scopes": "test_scope",
            "redirectUri": "com.test:/callback"
        ]

        do {
            _ = try OktaOidcConfig(with: dict)
        } catch let error {
            XCTAssertTrue(error.localizedDescription == OktaOidcError.missingConfigurationValues.errorDescription)
            return
        }

        dict = [
            "clientId": "",
            "issuer": "http://www.test.com",
            "scopes": "test_scope",
            "redirectUri": "com.test:/callback"
        ]
        
        do {
            _ = try OktaOidcConfig(with: dict)
        } catch let error {
            XCTAssertTrue(error.localizedDescription == OktaOidcError.missingConfigurationValues.errorDescription)
            return
        }

        dict = [
            "clientId": "test_client_id",
            "issuer": "http://www.test.com",
            "scopes": "test_scope",
            "redirectUri": ""
        ]
        
        do {
            _ = try OktaOidcConfig(with: dict)
        } catch let error {
            XCTAssertTrue(error.localizedDescription == OktaOidcError.missingConfigurationValues.errorDescription)
            return
        }
    }
    
    func testCloningConfigWithAdditionalParams() throws {
        let dict = [
            "clientId": "test_client_id",
            "issuer": "http://example.com",
            "scopes": "test_scope",
            "redirectUri": "com.test:/callback",
            "logoutRedirectUri": "com.test:/logout"
        ]
        
        let delegate = OktaNetworkRequestCustomizationDelegateMock()
        
        let configOrig = try OktaOidcConfig(with: dict)
        configOrig.requestCustomizationDelegate = delegate
        XCTAssertNotNil(configOrig)
        XCTAssertEqual(true, configOrig.additionalParams?.isEmpty)

        let configCopy1 = try configOrig.configuration(withAdditionalParams: ["additional": "param"])
        XCTAssertNotNil(configCopy1)
        XCTAssertEqual(configCopy1.additionalParams, ["additional": "param"])
        XCTAssertEqual(configOrig.clientId, configCopy1.clientId)
        XCTAssertEqual(configOrig.issuer, configCopy1.issuer)
        XCTAssertEqual(configOrig.scopes, configCopy1.scopes)
        XCTAssertEqual(configOrig.redirectUri, configCopy1.redirectUri)
        XCTAssertEqual(configOrig.logoutRedirectUri, configCopy1.logoutRedirectUri)
        XCTAssertEqual(configOrig.requestCustomizationDelegate as! OktaNetworkRequestCustomizationDelegateMock,
                       configCopy1.requestCustomizationDelegate as! OktaNetworkRequestCustomizationDelegateMock)
        XCTAssertEqual(configOrig.clientId, configCopy1.clientId)

        let configCopy2 = try configCopy1.configuration(withAdditionalParams: ["more": "params"])
        XCTAssertEqual(configCopy2.additionalParams, ["additional": "param", "more": "params"])
    }
    
    #if !SWIFT_PACKAGE
    /// **Note:** Unit tests in Swift Package Manager do not support tests run from a host application, meaning some iOS features are unavailable.
    func testDefaultConfig() {
        do {
            _ = try OktaOidcConfig.default()
        } catch let error {
            XCTAssertEqual(
                OktaOidcError.missingConfigurationValues.localizedDescription,
                error.localizedDescription
            )
        }
    }
    
    func testOktaPlist() {
        do {
            _ = try OktaOidcConfig(fromPlist: "Okta")
        } catch let error {
            XCTAssertEqual(
                OktaOidcError.missingConfigurationValues.localizedDescription,
                error.localizedDescription
            )
        }
    }
    
    func testPListParseFailure() {
        // Info.plist does not correspond to expected structure of Okta file
        let plistName = "Info"
        var config: OktaOidcConfig?
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
    #endif
    
    func testNoPListGiven() {
        // name of file which does not exists
        let plistName = UUID().uuidString
        var config: OktaOidcConfig?
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

    func testUserAgent() {
        OktaOidcConfig.setUserAgent(value: "some user agent")
        XCTAssertEqual(OktaUserAgent.userAgentHeaderValue(), "some user agent")
    }

    #if os(iOS) && !SWIFT_PACKAGE
    
    func testNoSSOOption() {
        do {
            if #available(iOS 13.0, *) {
                let config = try OktaOidcConfig.default()
                var oidc = OktaOidcBrowserTaskIOS(presenter: UIViewController(), config: config, oktaAPI: OktaOidcRestApi())
                var externalUA = oidc.externalUserAgent()
                XCTAssertTrue(externalUA is OKTExternalUserAgentIOS)

                config.noSSO = true
                oidc = OktaOidcBrowserTaskIOS(presenter: UIViewController(), config: config, oktaAPI: OktaOidcRestApi())
                externalUA = oidc.externalUserAgent()
                XCTAssertTrue(externalUA is OKTExternalUserAgentNoSsoIOS)
            }
        } catch let error {
            XCTAssertEqual(
                OktaOidcError.missingConfigurationValues.localizedDescription,
                error.localizedDescription
            )
        }
    }
    
    #endif
}
