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

class OktaOidcRestApiTests: XCTestCase {

    var sessionMock: URLSessionMock!

    override func setUp() {
        super.setUp()
        
        sessionMock = URLSessionMock()
        OKTURLSessionProvider.setSession(sessionMock)
    }

    func testFireRequest_DelegateNotNil() {
        let delegateMock = OktaNetworkRequestCustomizationDelegateMock()
        let oktaRestApi = OktaOidcRestApi()
        oktaRestApi.requestCustomizationDelegate = delegateMock

        let requestCompleteExpectation = expectation(description: "Request completed!")
        oktaRestApi.fireRequest(
            testRequest,
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

    func testFireRequest_CustomizedRequestIsNil() {
        let delegateMock = OktaNetworkRequestCustomizationDelegateMock()
        delegateMock.customizedRequest = nil
        let oktaRestApi = OktaOidcRestApi()
        oktaRestApi.requestCustomizationDelegate = delegateMock

        let requestCompleteExpectation = expectation(description: "Request completed!")
        oktaRestApi.fireRequest(
            testRequest,
            onSuccess: { _ in
                requestCompleteExpectation.fulfill()
            },
            onError: { _ in
                requestCompleteExpectation.fulfill()
                XCTFail("Request should be completed successfully")
            }
        )

        waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssertEqual(testRequest, sessionMock.request)
        XCTAssertTrue(delegateMock.didReceiveCalled)
    }

    func testFireRequest_DelegateNil() {
        let oktaRestApi = OktaOidcRestApi()

        let requestCompleteExpectation = expectation(description: "Request completed!")
        oktaRestApi.fireRequest(
            testRequest,
            onSuccess: { _ in
                requestCompleteExpectation.fulfill()
            },
            onError: { _ in
                requestCompleteExpectation.fulfill()
                XCTFail("Request should be completed successfully")
            }
        )

        waitForExpectations(timeout: 5.0, handler: nil)
        XCTAssertEqual(testRequest, sessionMock.request)
    }
}

private extension OktaOidcRestApiTests {

    var testRequest: URLRequest {
        return URLRequest(url: URL(string: "test")!)
    }
}
