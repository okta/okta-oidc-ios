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

#if os(macOS)

class OKTRedirectHTTPHandlerMock: OKTRedirectHTTPHandler {

    var startCalled = false
    var cancelCalled = false
    
    override func startHTTPListener(_ domain: String?) throws -> URL {
        startCalled = true
        return try super.startHTTPListener(domain)
    }

    override func startHTTPListener(_ domain: String?, withPort port: UInt16) throws -> URL {
        startCalled = true
        return try super.startHTTPListener(domain, withPort: port)
    }

    override func cancelHTTPListener() {
        cancelCalled = true
        super.cancelHTTPListener()
    }
}

#endif
