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

import Foundation
import OktaOidc

class OktaNetworkRequestCustomizationDelegateMock: NSObject, OktaNetworkRequestCustomizationDelegate {

    var customizedRequest: URLRequest? = URLRequest(url: URL(string: "customized_url")!)
    var didReceiveCalled = false

    func customizableURLRequest(_ request: URLRequest?) -> URLRequest? {
        return customizedRequest
    }

    func didReceive(_ response: URLResponse?) {
        didReceiveCalled = true
    }
}
