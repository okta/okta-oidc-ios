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

class OktaOidcRestApiTests: XCTestCase {

    func testFireRequest_DelegateNil() {
        let oktaRestApi = OktaOidcRestApi()
        let request = URLRequest(url: URL(string: "no_delegate_test")!)
        let sessionMock = URLSessionMock()
        OIDURLSessionProvider.setSession(sessionMock)

        let requestCompleteExpectation = expectation(description: "Request completed!")
        oktaRestApi.fireRequest(
            request,
            onSuccess: { _ in
                requestCompleteExpectation.fulfill()
            },
            onError: { _ in 
                requestCompleteExpectation.fulfill()
                XCTFail("Request should be completed successfully")
            }
        )

        waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssertEqual(request, sessionMock.request)
    }

    func testFireRequest_DelegateNotNil() {
        let delegateMock = OktaNetworkRequestCustomizationDelegateMock()
        let oktaRestApi = OktaOidcRestApi(delegate: delegateMock)
        let request = URLRequest(url: URL(string: "test")!)
        let sessionMock = URLSessionMock()
        OIDURLSessionProvider.setSession(sessionMock)

        let requestCompleteExpectation = expectation(description: "Request completed!")
        oktaRestApi.fireRequest(
            request,
            onSuccess: { _ in
                requestCompleteExpectation.fulfill()
            },
            onError: { _ in 
                requestCompleteExpectation.fulfill()
                XCTFail("Request should be completed successfully")
            }
        )

        waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssertEqual(delegateMock.customizedRequest, sessionMock.request)
        XCTAssertTrue(delegateMock.didReceiveCalled)
    }
}
