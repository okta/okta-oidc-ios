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

class OIDExternalUserAgentRequestMock: OIDExternalUserAgentRequest {
    func externalUserAgentRequestURL() -> URL! {
        return URL(string: "https://tenant.okta.com")!
    }
    
    func redirectScheme() -> String! {
        return "com.okta.callback://oauth/callback"
    }
}

class OIDExternalUserAgentSessionNoSsoMock: NSObject, OIDExternalUserAgentSession {

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

class OIDExternalUserAgentNoSsoIOSPartialMock: OIDExternalUserAgentNoSsoIOS {
@available(iOS 13.0, *)
    override func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIWindow()
    }
}

class OIDExternalUserAgentNoSsoTests: XCTestCase {

    func testCreateNoSsoExternalUserAgent_Success() {
        if #available(iOS 13.0, *) {
            let mut = OIDExternalUserAgentNoSsoIOSPartialMock(presenting: UIViewController())
            XCTAssertTrue(mut.present(OIDExternalUserAgentRequestMock(), session: OIDExternalUserAgentSessionNoSsoMock()))
        }
    }

    func testCreateNoSsoExternalUserAgent_Failure() {
        if #available(iOS 13.0, *) {
            let mut = OIDExternalUserAgentNoSsoIOS(presenting: UIViewController())
            let sessionMock = OIDExternalUserAgentSessionNoSsoMock()
            XCTAssertFalse(mut.present(OIDExternalUserAgentRequestMock(), session: sessionMock))
            XCTAssertTrue(sessionMock.failExternalUserAgentFlowWithErrorCalled)
            XCTAssertNotNil(sessionMock.error)
        }
    }
}
