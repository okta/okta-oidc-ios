/*
 * Copyright (c) 2017-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

#if os(macOS)

import Foundation

#if SWIFT_PACKAGE
@testable import OktaOidc_AppAuth
#endif

public class OktaRedirectServer {

    var redirectHandler: OKTRedirectHTTPHandler
    let port: UInt16

    public init(successURL: URL?, port: UInt16 = 0) {
        redirectHandler = OKTRedirectHTTPHandler(successURL: successURL)
        self.port = port
    }

    public func startListener(with domainName: String? = nil) throws -> URL {
        if port == 0 {
            return try startListenerOnRandomPort(with: domainName)
        } else {
            return try redirectHandler.startHTTPListener(domainName, withPort: port)
        }
    }

    public func stopListener() {
        redirectHandler.cancelHTTPListener()
    }

    private func startListenerOnRandomPort(with domainName: String? = nil) throws -> URL {
        return try redirectHandler.startHTTPListener(domainName)
    }
}

#endif
