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

#if SWIFT_PACKAGE
@testable import TestCommon
#endif

class OKTAuthorizationServiceRequestDelegateTests: XCTestCase {

    var sessionMock: URLSessionMock!

    override func setUp() {
        super.setUp()
        
        sessionMock = URLSessionMock()
        OKTURLSessionProvider.setSession(sessionMock)
    }

    func testPerformTokenRequest_DelegateNotNil() {
        let delegateMock = OktaNetworkRequestCustomizationDelegateMock()

        let requestCompleteExpectation = expectation(description: "Request completed!")
        OKTAuthorizationService.perform(mockTokenRequest, delegate: delegateMock) { _, _ in
            requestCompleteExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssertEqual(delegateMock.customizedRequest, sessionMock.request)
        XCTAssertTrue(delegateMock.didReceiveCalled)
    }

    func testPerformAuthorizationRequest_DelegateNotNil() {
        let delegateMock = OktaNetworkRequestCustomizationDelegateMock()

        let requestCompleteExpectation = expectation(description: "Request completed!")
        OKTAuthorizationService.perform(mockRegistrationRequest, delegate: delegateMock) { _, _ in
            requestCompleteExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssertEqual(delegateMock.customizedRequest, sessionMock.request)
        XCTAssertTrue(delegateMock.didReceiveCalled)
    }
}

private extension OKTAuthorizationServiceRequestDelegateTests {

    var testUrl: URL {
        return URL(string: TestUtils.mockIssuer)!
    }

    var mockServiceConfig: OKTServiceConfiguration {
        return .init(authorizationEndpoint: testUrl, tokenEndpoint: testUrl, issuer: testUrl)
    }

    var mockTokenRequest: OKTTokenRequest {
        return .init(
            configuration: mockServiceConfig,
            grantType: OKTGrantTypeRefreshToken,
            authorizationCode: nil,
            redirectURL: testUrl,
            clientID: "nil",
            clientSecret: nil,
            scope: nil,
            refreshToken: nil,
            codeVerifier: nil,
            additionalParameters: nil
        )
    }

    var mockRegistrationRequest: OKTRegistrationRequest {
        return .init(
            configuration: mockServiceConfig,
            redirectURIs: [testUrl],
            responseTypes: nil,
            grantTypes: nil,
            subjectType: nil,
            tokenEndpointAuthMethod: nil,
            additionalParameters: nil
        )
    }
}
