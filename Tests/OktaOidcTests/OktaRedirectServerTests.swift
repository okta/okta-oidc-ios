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

#if os(macOS)

class OktaRedirectServerTests: XCTestCase {

    func testRedirectServerCreate() {
        var server = OktaRedirectServer(successURL: nil)
        XCTAssertEqual(server.port, 0)
        server = OktaRedirectServer(successURL: nil, port: 61678)
        XCTAssertEqual(server.port, 61678)
    }

    func testStartListener() {
        // listener with default port 63875
        var server = createRedirectServer(successURL: nil)
        var url = try? server.startListener()
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, "http://127.0.0.1:63875/")
        XCTAssert(mockedRedirectHTTPHandler(for: server).startCalled)
        server.stopListener()
        XCTAssert(mockedRedirectHTTPHandler(for: server).cancelCalled)

        // listener with custom port 60123
        server = createRedirectServer(successURL: nil, port: 60123)
        url = try? server.startListener()
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, "http://127.0.0.1:60123/")
        XCTAssert(mockedRedirectHTTPHandler(for: server).startCalled)
        server.stopListener()
        XCTAssert(mockedRedirectHTTPHandler(for: server).cancelCalled)

        // listener with custom domain and custom port 60123
        server = createRedirectServer(successURL: nil, port: 60123)
        url = try? server.startListener(with: "localhost")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, "http://localhost:60123/")
        XCTAssert(mockedRedirectHTTPHandler(for: server).startCalled)
        server.stopListener()
        XCTAssert(mockedRedirectHTTPHandler(for: server).cancelCalled)
    }

    func createRedirectServer(successURL: URL?, port: UInt16 = 0) -> OktaRedirectServer {
        let server = OktaRedirectServer(successURL: nil, port: port)
        server.redirectHandler = OKTRedirectHTTPHandlerMock()
        return server
    }

    func mockedRedirectHTTPHandler(for server: OktaRedirectServer) -> OKTRedirectHTTPHandlerMock {
        return server.redirectHandler as! OKTRedirectHTTPHandlerMock
    }
}

#endif
