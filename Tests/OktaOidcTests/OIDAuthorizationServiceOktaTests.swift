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

class OKTAuthorizationServiceOktaTests: XCTestCase {

    var sessionMock: URLSessionMock!

    override func setUp() {
        super.setUp()
        
        sessionMock = URLSessionMock()
        OKTURLSessionProvider.setSession(sessionMock)
    }

    func testPerformAuthRequest_DelegateNotNil() {
        let delegateMock = OktaNetworkRequestCustomizationDelegateMock()

        let requestCompleteExpectation = expectation(description: "Request completed!")
        OKTAuthorizationService.perform(
            authRequest: mockAuthRequest,
            delegate: delegateMock
        ) { (_, _) in
            requestCompleteExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssertEqual(delegateMock.customizedRequest, sessionMock.request)
        XCTAssertTrue(delegateMock.didReceiveCalled)
    }

    func testPerformAuthRequest_CustomizedRequestIsNil() {
        let delegateMock = OktaNetworkRequestCustomizationDelegateMock()
        delegateMock.customizedRequest = nil

        let requestCompleteExpectation = expectation(description: "Request completed!")
        OKTAuthorizationService.perform(
            authRequest: mockAuthRequest,
            delegate: delegateMock
        ) { (_, _) in
            requestCompleteExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssertNotNil(sessionMock.request)
        XCTAssertTrue(delegateMock.didReceiveCalled)
    }

    func testPerformAuthRequest_DelegateIsNil() {
        let requestCompleteExpectation = expectation(description: "Request completed!")
        OKTAuthorizationService.perform(authRequest: mockAuthRequest) { (_, _) in
            requestCompleteExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssertNotNil(sessionMock.request)
    }
}

private extension OKTAuthorizationServiceOktaTests {

    var mockAuthRequest: OKTAuthorizationRequest {
        let testUrl = URL(string: TestUtils.mockIssuer)!
        let testConfig = OKTServiceConfiguration(authorizationEndpoint: testUrl, tokenEndpoint: testUrl, issuer: testUrl)
        return .init(
            configuration: testConfig,
            clientId: TestUtils.mockClientId,
            clientSecret: nil,
            scopes: ["openid", "email"],
            redirectURL: testUrl,
            responseType: OKTResponseTypeCode,
            additionalParameters: nil
        )
    }
}
