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

class OKTExternalUserAgentRequestMock: OKTExternalUserAgentRequest {
    func externalUserAgentRequestURL() -> URL! {
        return URL(string: "https://tenant.okta.com")!
    }
    
    func redirectScheme() -> String {
      "com.okta.callback"
    }
}

class OKTExternalUserAgentSessionNoSsoMock: NSObject, OKTExternalUserAgentSession {

    var cancelCalled = false
    var resumeExternalUserAgentFlowCalled = false
    var failExternalUserAgentFlowWithErrorCalled = false
    var error: Error?
    
    override init() {
    }
    
    func cancel() {
        cancelCalled = true
    }
    
    func cancel(completion: (() -> Void)? = nil) {
        cancelCalled = true
    }
    
    func resumeExternalUserAgentFlow(with URL: URL) -> Bool {
        resumeExternalUserAgentFlowCalled = true
        return true
    }
    
    func failExternalUserAgentFlowWithError(_ error: Error) {
        failExternalUserAgentFlowWithErrorCalled = true
        self.error = error
    }
}

#if os(iOS)

class OKTExternalUserAgentNoSsoIOSPartialMock: OKTExternalUserAgentNoSsoIOS {
@available(iOS 13.0, *)
    override func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIWindow()
    }
}

class OKTExternalUserAgentNoSsoTests: XCTestCase {

    func testCreateNoSsoExternalUserAgent_Success() {
        if #available(iOS 13.0, *) {
            let mut = OKTExternalUserAgentNoSsoIOSPartialMock(presenting: UIViewController())
            XCTAssertTrue(mut.present(OKTExternalUserAgentRequestMock(), session: OKTExternalUserAgentSessionNoSsoMock()))
        }
    }

    #if !SWIFT_PACKAGE
    /// **Note:** Unit tests in Swift Package Manager do not support tests run from a host application, meaning some iOS features are unavailable.

    func testCreateNoSsoExternalUserAgent_Failure() {
        if #available(iOS 13.0, *) {
            let mut = OKTExternalUserAgentNoSsoIOS(presenting: UIViewController())
            let sessionMock = OKTExternalUserAgentSessionNoSsoMock()
            XCTAssertFalse(mut.present(OKTExternalUserAgentRequestMock(), session: sessionMock))
            XCTAssertTrue(sessionMock.failExternalUserAgentFlowWithErrorCalled)
            XCTAssertNotNil(sessionMock.error)
        }
    }
    
    #endif
}

#endif
