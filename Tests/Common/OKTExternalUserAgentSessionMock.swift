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

import Foundation
@testable import OktaOidc

class OKTExternalUserAgentSessionMock: NSObject, OKTExternalUserAgentSession {

    let signCallback: OKTAuthStateAuthorizationCallback?
    let signOutCallback: OKTEndSessionCallback?
    
    init(signCallback: OKTAuthStateAuthorizationCallback?, signOutCallback: OKTEndSessionCallback?) {
        self.signCallback = signCallback
        self.signOutCallback = signOutCallback
    }
    
    func cancel() {
        DispatchQueue.main.async {
            self.signCallback?(nil, self.error())
            self.signOutCallback?(nil, self.error())
        }
    }
    
    func cancel(completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            completion?()
            self.signCallback?(nil, self.error())
            self.signOutCallback?(nil, self.error())
        }
    }
    
    func resumeExternalUserAgentFlow(with URL: URL) -> Bool {
        return true
    }
    
    func failExternalUserAgentFlowWithError(_ error: Error) {
        
    }

    private func error() -> NSError {
        return NSError(domain: "useragent.mock", code: -999, userInfo: [NSLocalizedDescriptionKey: "Authorization flow was cancelled."])
    }
}
