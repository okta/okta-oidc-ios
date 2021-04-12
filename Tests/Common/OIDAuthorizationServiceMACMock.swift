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

// swiftlint:disable force_try
// swiftlint:disable force_cast
// swiftlint:disable force_unwrapping

import Foundation
@testable import OktaOidc

class OKTAuthorizationServiceMACMock: OKTAuthorizationService {
    override class func present(_ request: OKTEndSessionRequest,
                                externalUserAgent: OKTExternalUserAgent,
                                callback: @escaping OKTEndSessionCallback) -> OKTExternalUserAgentSession {
        DispatchQueue.main.async {
            // http://127.0.0.1:60000/ - is intended for cancellation tests
            if request.postLogoutRedirectURL?.absoluteString != "http://127.0.0.1:60000/" {
                // hit loopback server
                let task = URLSession.shared.dataTask(with: request.postLogoutRedirectURL!) { (_, _, error) in
                    if let error = error {
                        callback(nil, error)
                    } else {
                        let endSessionResponse = OKTEndSessionResponse(request: request, parameters: [:])
                        callback(endSessionResponse, nil)
                    }
                }

                task.resume()
            }
        }
        return OKTExternalUserAgentSessionMock(signCallback: nil, signOutCallback: callback)
    }
}
