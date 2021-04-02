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

#if os(macOS)
import AppKit

@objc public protocol OktaOidcBrowserProtocolMAC {
    func signInWithBrowser(redirectServerConfiguration: OktaRedirectServerConfiguration?,
                           callback: @escaping ((OktaOidcStateManager?, Error?) -> Void))
    func signOutOfOkta(authStateManager: OktaOidcStateManager,
                       redirectServerConfiguration: OktaRedirectServerConfiguration?,
                       callback: @escaping ((Error?) -> Void))
    func cancelBrowserSession(completion: (() -> Void)?)
}

public extension OktaOidcBrowserProtocolMAC {
    func signInWithBrowser(redirectServerConfiguration: OktaRedirectServerConfiguration? = nil,
                           callback: @escaping ((OktaOidcStateManager?, Error?) -> Void)) {
        signInWithBrowser(redirectServerConfiguration: redirectServerConfiguration,
                          callback: callback)
    }
    func signOutOfOkta(authStateManager: OktaOidcStateManager,
                       redirectServerConfiguration: OktaRedirectServerConfiguration? = nil,
                       callback: @escaping ((Error?) -> Void)) {
        signOutOfOkta(authStateManager: authStateManager,
                      redirectServerConfiguration: redirectServerConfiguration,
                      callback: callback)
    }
    func cancelBrowserSession(completion: (() -> Void)? = nil) {
        cancelBrowserSession(completion: completion)
    }
}
#endif
