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

public enum OktaOidcError: Error {
    case APIError(String)
    case errorFetchingFreshTokens(String)
    case JWTDecodeError
    case JWTValidationError(String)
    case missingConfigurationValues
    case noBearerToken
    case noDiscoveryEndpoint
    case noIntrospectionEndpoint
    case noPListGiven
    case pListParseFailure
    case notConfigured
    case noRefreshToken
    case noRevocationEndpoint
    case noTokens
    case noUserInfoEndpoint
    case parseFailure
    case missingIdToken
    case unexpectedAuthCodeResponse
    case unableToGetAuthCode
}

extension OktaOidcError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .APIError(error: let error):
            return NSLocalizedString(error, comment: "")
        case .errorFetchingFreshTokens(error: let error):
            return NSLocalizedString("Error fetching fresh tokens: \(error)", comment: "")
        case .JWTDecodeError:
            return NSLocalizedString("Could not parse the given JWT string payload.", comment: "")
        case .JWTValidationError(error: let error):
            return NSLocalizedString("Could not validate the JWT: \(error)", comment: "")
        case .missingConfigurationValues:
            return NSLocalizedString("Could not parse 'issuer', 'clientId', and/or 'redirectUri' plist values. " +
                "See https://github.com/okta/okta-sdk-appauth-ios/#configuration for more information.", comment: "")
        case .noBearerToken:
            return NSLocalizedString("Missing Bearer token. You must authenticate first.", comment: "")
        case .noDiscoveryEndpoint:
            return NSLocalizedString("Error finding the well-known OpenID Configuration endpoint.", comment: "")
        case .noIntrospectionEndpoint:
            return NSLocalizedString("Error finding the introspection endpoint.", comment: "")
        case .noPListGiven:
            return NSLocalizedString("PList name required. See https://github.com/okta/okta-sdk-appauth-ios/#configuration for more information.", comment: "")
        case .pListParseFailure:
            return NSLocalizedString("Unable to read and/or parse. See https://github.com/okta/okta-sdk-appauth-ios/#configuration for more information.", comment: "")
        case .notConfigured:
            return NSLocalizedString("You must configure the OktaOidc SDK first. See https://github.com/okta/okta-sdk-appauth-ios/#configuration for more information.", comment: "")
        case .noRefreshToken:
            return NSLocalizedString("No refresh token stored. Make sure the 'offline_access' scope is included in your PList.", comment: "")
        case .noRevocationEndpoint:
            return NSLocalizedString("Error finding the revocation endpoint.", comment: "")
        case .noTokens:
            return NSLocalizedString("No tokens stored in the auth state manager.", comment: "")
        case .noUserInfoEndpoint:
            return NSLocalizedString("Error finding the user info endpoint.", comment: "")
        case .parseFailure:
            return NSLocalizedString("Failed to parse and/or convert object.", comment: "")
        case .missingIdToken:
            return NSLocalizedString("ID token needed to fulfill this operation.", comment: "")
        case .unexpectedAuthCodeResponse:
            return NSLocalizedString("Unexpected response format while retrieving authorization code.", comment: "")
        case .unableToGetAuthCode:
            return NSLocalizedString("Unable to get authorization code.", comment: "")
        }
    }
}
