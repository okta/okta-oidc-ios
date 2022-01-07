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

public enum OktaOidcError: CustomNSError {
    
    /// See [RFC6749 Error Response](https://tools.ietf.org/html/rfc6749#section-4.1.2.1).
    case authorization(error: String, description: String?)
    
    case api(message: String, underlyingError: Error?)
    case unexpectedAuthCodeResponse(statusCode: Int)
    case errorFetchingFreshTokens(String)
    case JWTValidationError(String)
    case redirectServerError(String)
    case JWTDecodeError
    case noLocationHeader
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
    case userCancelledAuthorizationFlow
    case unableToGetAuthCode
    case unableToOpenBrowser // macOS specific
    
    public static var errorDomain: String = "\(Self.self)"
    
    /// Most of errors returns the general error code.
    /// Error like `api`, `unexpectedAuthCodeResponse` return specific error code.
    /// `api` returns the general error code if `underlyingError` is absent. 
    static let generalErrorCode = -1012009
    
    public var errorCode: Int {
        switch self {
        case let .api(_, underlyingError):
            return (underlyingError as NSError?)?.code ?? Self.generalErrorCode
            
        case let .unexpectedAuthCodeResponse(statusCode):
            return statusCode
        default:
            return Self.generalErrorCode
        }
    }
    
    public var errorUserInfo: [String: Any] {
        var result: [String: Any] = [:]
        result[NSLocalizedDescriptionKey] = errorDescription
        
        switch self {
        case let .api(_, underlyingError):
            result[NSUnderlyingErrorKey] = underlyingError
            return result
        default:
            return result
        }
    }
}

extension OktaOidcError: Equatable {
    public static func == (lhs: OktaOidcError, rhs: OktaOidcError) -> Bool {
        lhs as NSError == rhs as NSError
    }
}

extension OktaOidcError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .api(message, _):
            return NSLocalizedString(message, comment: "")
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
        case .unexpectedAuthCodeResponse(let statusCode):
            return NSLocalizedString("Unexpected response format while retrieving authorization code. Status code: \(statusCode)", comment: "")
        case .userCancelledAuthorizationFlow:
            return NSLocalizedString("User cancelled current session", comment: "")
        case .unableToGetAuthCode:
            return NSLocalizedString("Unable to get authorization code.", comment: "")
        case .redirectServerError(error: let error):
            return NSLocalizedString(error, comment: "")
        case let .authorization(error, description):
            return NSLocalizedString("The authorization request failed due to \(error): \(description ?? "")", comment: "")
        case .noLocationHeader:
            return NSLocalizedString("Unable to get location header.", comment: "")
        case .unableToOpenBrowser:
            return NSLocalizedString("Error triggering authorization flow in default system browser. NSWorkspace.openURL returned false.", comment: "")

        }
    }
}
