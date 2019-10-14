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

import Foundation

public class OktaRedirectServer: NSObject {

    var redirectHandler: OIDRedirectHTTPHandler!
    let port: UInt16

    public init(successURL: URL?, port: UInt16) {
        redirectHandler = OIDRedirectHTTPHandler(successURL: successURL)
        self.port = port
    }

    public func startListener() throws -> URL {
        if port == 0 {
            return try startListenerOnRandomPort()
        } else {
            var error: NSError? = nil
            guard let redirectUrl = redirectHandler.startHTTPListener(&error, withPort: port) else {
                throw error ?? NSError()
            }
            return redirectUrl
        }
    }

    public func stopListener() {
        redirectHandler.cancelHTTPListener()
    }

    private func startListenerOnRandomPort() throws -> URL {
        return try redirectHandler.startHTTPListener()
    }
}
