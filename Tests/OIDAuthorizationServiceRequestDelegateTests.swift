/*
 * Copyright (c) 2020, Okta, Inc. and/or its affiliates. All rights reserved.
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

class OIDAuthorizationServiceRequestDelegateTests: XCTestCase {

    func testPerformTokenRequest_DelegateNotNil() {
        let delegateMock = OktaNetworkRequestCustomizationDelegateMock()
        let sessionMock = URLSessionMock()
        OIDURLSessionProvider.setSession(sessionMock)

        let requestCompleteExpectation = expectation(description: "Request completed!")
        OIDAuthorizationService.perform(mockTokenRequest, delegate: delegateMock) { _, _ in
            requestCompleteExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssertEqual(delegateMock.customizedRequest, sessionMock.request)
        XCTAssertTrue(delegateMock.didReceiveCalled)
    }

    func testPerformAuthorizationRequest_DelegateNotNil() {
        let delegateMock = OktaNetworkRequestCustomizationDelegateMock()
        let sessionMock = URLSessionMock()
        OIDURLSessionProvider.setSession(sessionMock)

        let requestCompleteExpectation = expectation(description: "Request completed!")
        OIDAuthorizationService.perform(mockRegistrationRequest, delegate: delegateMock) { _, _ in
            requestCompleteExpectation.fulfill()
        }

        waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssertEqual(delegateMock.customizedRequest, sessionMock.request)
        XCTAssertTrue(delegateMock.didReceiveCalled)
    }
}

private extension OIDAuthorizationServiceRequestDelegateTests {

    var testUrl: URL {
        return URL(string: TestUtils.mockIssuer)!
    }

    var mockServiceConfig: OIDServiceConfiguration {
        return .init(authorizationEndpoint: testUrl, tokenEndpoint: testUrl, issuer: testUrl)
    }

    var mockTokenRequest: OIDTokenRequest {
        return .init(
            configuration: mockServiceConfig,
            grantType: OIDGrantTypeRefreshToken,
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

    var mockRegistrationRequest: OIDRegistrationRequest {
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
