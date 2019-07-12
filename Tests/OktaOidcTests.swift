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

class OktaOidcTests: XCTestCase {

    private let issuer = ProcessInfo.processInfo.environment["ISSUER"]!
    private let clientId = ProcessInfo.processInfo.environment["CLIENT_ID"]!
    private let redirectUri = ProcessInfo.processInfo.environment["REDIRECT_URI"]!
    private let logoutRedirectUri = ProcessInfo.processInfo.environment["LOGOUT_REDIRECT_URI"]!
    
    private var envConfig: OktaOidcConfig? {
        return try? OktaOidcConfig(with:[
            "issuer": issuer,
            "clientId": clientId,
            "redirectUri": redirectUri,
            "logoutRedirectUri": logoutRedirectUri,
            "scopes": "openid profile offline_access"
        ])
    }
    
    func testCreationWithNil() {
        // Depends on whether Okta.plist is configured or not
        if let defaultConfig = try? OktaOidcConfig.default() {
            let oktaOidc = try? OktaOidc()
            XCTAssertNotNil(oktaOidc)
            XCTAssertEqual(defaultConfig, oktaOidc?.configuration)
        } else {
            XCTAssertThrowsError(try OktaOidc()) { error in
                XCTAssertEqual(
                    OktaOidcError.missingConfigurationValues.localizedDescription,
                    error.localizedDescription
                )
            }
        }
    }
    
    func testCreationWithEnvConfig() {
        guard let envConfig = envConfig else {
            XCTFail("Please, configure environment variables to create config!")
            return
        }

        let oktaOidc = try? OktaOidc(configuration: envConfig)
        XCTAssertNotNil(oktaOidc)
    }
}
