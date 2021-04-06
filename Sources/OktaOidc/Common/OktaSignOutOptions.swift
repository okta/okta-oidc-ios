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

public struct OktaSignOutOptions: OptionSet {
    
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let revokeAccessToken        = OktaSignOutOptions(rawValue: 1 << 0)
    public static let revokeRefreshToken       = OktaSignOutOptions(rawValue: 1 << 1)
    public static let signOutFromOkta          = OktaSignOutOptions(rawValue: 1 << 2)
    public static let removeTokensFromStorage  = OktaSignOutOptions(rawValue: 1 << 3)
    
    public static let revokeTokensOptions: OktaSignOutOptions = [.revokeAccessToken, .revokeRefreshToken]
    public static let allOptions: OktaSignOutOptions = [.revokeAccessToken, .revokeRefreshToken, .signOutFromOkta, .removeTokensFromStorage]
}
