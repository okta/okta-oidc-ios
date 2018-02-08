/*
 * Copyright (c) 2017, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

public enum OktaError: Error {
    case APIError(String)
    case NoClientSecret(String)
    case NoDiscoveryEndpoint
    case NoIntrospectionEndpoint
    case NoPListGiven
    case NoRevocationEndpoint
    case NoUserCredentials
    case NoUserInfoEndpoint
}

extension OktaError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .APIError(error: let error):
            return NSLocalizedString(error, comment: "")
        case .NoClientSecret(plist: let plist):
            return NSLocalizedString(
                "ClientSecret not included in PList configuration file: " +
                    "\(plist). See https://github.com/okta/okta-sdk-appauth-ios/#configuration " +
                "for more information.", comment: "")
        case .NoDiscoveryEndpoint:
            return NSLocalizedString("Error finding the well-known OpenID Configuration endpoint.", comment: "")
        case .NoIntrospectionEndpoint:
            return NSLocalizedString("Error finding the introspection endpoint.", comment: "")
        case .NoPListGiven:
            return NSLocalizedString("PList name required. See https://github.com/okta/okta-sdk-appauth-ios/#configuration for more information.", comment: "")
        case .NoRevocationEndpoint:
            return NSLocalizedString("Error finding the revocation endpoint.", comment: "")
        case .NoUserCredentials:
            return NSLocalizedString("User credentials not included.", comment: "")
        case .NoUserInfoEndpoint:
            return NSLocalizedString("Error finding the user info endpoint.", comment: "")
        }
    }
}
