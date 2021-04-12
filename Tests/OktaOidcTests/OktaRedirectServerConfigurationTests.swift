/*
 * Copyright (c) 2020-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

#if os(macOS)

class OktaRedirectServerConfigurationTests: XCTestCase {

    func testConfigCreation() {
        let testConfig = OktaRedirectServerConfiguration(successRedirectURL: URL(string: "http://test.okta.com"), port: 63210, domainName: "localhost")
        XCTAssertEqual(testConfig.successRedirectURL, URL(string: "http://test.okta.com")!)
        XCTAssertEqual(testConfig.port, 63210)
        XCTAssertEqual(testConfig.domainName, "localhost")
    }

    func testDefaultConfig() {
        let testConfig = OktaRedirectServerConfiguration.default
        XCTAssertEqual(testConfig.successRedirectURL, URL(string: "http://openid.github.io/AppAuth-iOS/redirect/")!)
        XCTAssertNil(testConfig.port)
        XCTAssertNil(testConfig.domainName)
    }
}

#endif
