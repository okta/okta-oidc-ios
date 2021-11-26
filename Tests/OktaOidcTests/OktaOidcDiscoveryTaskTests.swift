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

class OktaOidcDiscoveryTaskTests: XCTestCase {

    var apiMock: OktaOidcApiMock!
    
    override func setUp() {
        super.setUp()
        
        apiMock = OktaOidcApiMock()
    }

    override func tearDown() {
        apiMock = nil
        super.tearDown()
    }
    
    func testRunSucceeded() {
        apiMock.configure(response: self.validOKTConfigDictionary)
        
        runAndWaitDiscovery(config: validConfig) { oidConfig, error in
            XCTAssertNil(error)
            XCTAssertEqual("http://test.issuer.com/oauth2/authorize", oidConfig?.authorizationEndpoint.absoluteString)
            XCTAssertEqual("http://test.issuer.com/oauth2/token", oidConfig?.tokenEndpoint.absoluteString)
            XCTAssertEqual("http://test.issuer.com/oauth2/default", oidConfig?.issuer?.absoluteString)
        }
    }
    
    func testRunApiError() {
        let mockError = OktaOidcError.api(message: "Test Error", underlyingError: nil)
        apiMock.configure(error: mockError)
        
        runAndWaitDiscovery(config: validConfig) { oidConfig, error in
            XCTAssertNil(oidConfig)
            XCTAssertEqual(mockError, error as OktaOidcError?)
        }
    }
    
    func testRunParseError() {
        apiMock.configure(response: ["invalidKey": ""])
        
        runAndWaitDiscovery(config: validConfig) { oidConfig, error in
            XCTAssertNil(oidConfig)
            XCTAssertEqual(
                OktaOidcError.parseFailure.localizedDescription,
                error?.localizedDescription
            )
        }
    }
    
    func testRunDiscoveryEndpointURL() {
        apiMock.configure(response: validOKTConfigDictionary) { request in
            XCTAssertEqual(
                "http://test.issuer.com/oauth2/default/.well-known/openid-configuration",
                request.url?.absoluteString
            )
        }
        
        runAndWaitDiscovery(config: validConfig) { oidConfig, error in
            XCTAssertNil(error)
            XCTAssertNotNil(oidConfig)
        }
    }
    
    // MARK: - Utils
    
    private func runAndWaitDiscovery(config: OktaOidcConfig,
                                      validationHandler: @escaping (OKTServiceConfiguration?, OktaOidcError?) -> Void) {
        let ex = expectation(description: "User Info should be called!")
        DispatchQueue.global().async {
            OktaOidcTask(config: config, oktaAPI: self.apiMock).downloadOidcConfiguration() { oidConfig, error in
                XCTAssert(Thread.current.isMainThread)
                validationHandler(oidConfig, error)
                ex.fulfill()
            }
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    private var validConfig: OktaOidcConfig {
        return try! OktaOidcConfig(with: [
            "issuer": "http://test.issuer.com/oauth2/default",
            "clientId": "test_client",
            "scopes": "test",
            "redirectUri": "test:/callback"
        ])
    }
    
    private var validOKTConfigDictionary: [String: Any] {
        return [
            "issuer": "http://test.issuer.com/oauth2/default",
            "authorization_endpoint": "http://test.issuer.com/oauth2/authorize",
            "token_endpoint": "http://test.issuer.com/oauth2/token",
            "jwks_uri": "http://test.issuer.com/oauth2/default/v1/keys",
            "response_types_supported": ["code"],
            "subject_types_supported": ["public"],
            "id_token_signing_alg_values_supported": ["RS256"]
        ]
    }
}
