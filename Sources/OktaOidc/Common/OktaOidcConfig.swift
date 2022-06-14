/*
 * Copyright (c) 2019-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

#if SWIFT_PACKAGE
import OktaOidc_AppAuth
#endif

public class OktaOidcConfig: NSObject {
    @objc public static let defaultPlistName = "Okta"
    
    @objc public let clientId: String
    @objc public let issuer: String
    @objc public let scopes: String
    @objc public let redirectUri: URL
    @objc public let logoutRedirectUri: URL?

    /*!
     Set the request customization delegate if you want to track and modify network
     requests throughout OktaOidc. More information could be found here: https://github.com/okta/okta-oidc-ios/blob/master/README.md#modify-network-requests.
     */
    @objc public weak var requestCustomizationDelegate: OktaNetworkRequestCustomizationDelegate?
    
    @objc public var tokenValidator: OKTTokenValidator = OKTDefaultTokenValidator()
    
    private var _noSSO = false
    
    @available(iOS 13.0, *)
    @objc public var noSSO: Bool {
        get { _noSSO }
        set { _noSSO = newValue }
    }
    
    @objc public let additionalParams: [String: String]?

    @objc public static func `default`() throws -> OktaOidcConfig {
        return try OktaOidcConfig(fromPlist: defaultPlistName)
    }

    @objc public init(with dict: [String: String]) throws {
        guard let clientId = dict["clientId"], !clientId.isEmpty,
              let issuer = dict["issuer"], URL(string: issuer) != nil,
              let scopes = dict["scopes"], !scopes.isEmpty,
              let redirectUriString = dict["redirectUri"],
              let redirectUri = URL(string: redirectUriString) else {
                throw OktaOidcError.missingConfigurationValues
        }
        
        self.clientId = clientId
        self.issuer = issuer
        self.scopes = scopes
        self.redirectUri = redirectUri
        
        if let logoutRedirectUriString = dict["logoutRedirectUri"] {
            logoutRedirectUri = URL(string: logoutRedirectUriString)
        } else {
            logoutRedirectUri = nil
        }
        
        additionalParams = OktaOidcConfig.extractAdditionalParams(dict)
        OktaOidcConfig.setupURLSession()
    }

    @objc public convenience init(fromPlist plistName: String) throws {
        guard let path = Bundle.main.url(forResource: plistName, withExtension: "plist") else {
            throw OktaOidcError.noPListGiven
        }
        
        guard let data = try? Data(contentsOf: path),
            let plistContent = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
            let configDict = plistContent as? [String: String] else {
                throw OktaOidcError.pListParseFailure
        }
        
        try self.init(with: configDict)
    }

    public class func setUserAgent(value: String) {
        OktaUserAgent.setUserAgentValue(value)
    }
    
    override public func isEqual(_ object: Any?) -> Bool {
        guard let config = object as? OktaOidcConfig else {
            return false
        }
        if #available(iOS 13.0, *) {
            if self.noSSO != config.noSSO {
                return false
            }
        }

        return self.clientId == config.clientId &&
               self.issuer == config.issuer &&
               self.scopes == config.scopes &&
               self.redirectUri == config.redirectUri &&
               self.logoutRedirectUri == config.logoutRedirectUri &&
               self.additionalParams == config.additionalParams
    }

    class func setupURLSession() {
        /*
         Setup auth session to block redirection because authorization request
         implies redirection and passing authCode as a query parameter.
        */
        let config = URLSessionConfiguration.default
        config.httpShouldSetCookies = false
        config.httpAdditionalHeaders = [[OktaUserAgent.userAgentHeaderKey()]: [OktaUserAgent.userAgentHeaderValue()]]

        let session = URLSession(
            configuration: config,
            delegate: RedirectBlockingURLSessionDelegate.shared,
            delegateQueue: .main)
        
        OKTURLSessionProvider.setSession(session)
    }
    
    public func configuration(withAdditionalParams config: [String: String]) throws -> OktaOidcConfig {
        guard !config.isEmpty else {
            return self
        }

        var dict: [String: String] = additionalParams?.merging(config, uniquingKeysWith: { (_, new) -> String in
            return new
        }) ?? config
        
        dict["issuer"] = issuer
        dict["clientId"] = clientId
        dict["redirectUri"] = redirectUri.absoluteString
        dict["scopes"] = scopes
        if let logoutRedirectUri = logoutRedirectUri {
            dict["logoutRedirectUri"] = logoutRedirectUri.absoluteString
        }
        
        let result = try OktaOidcConfig(with: dict)
        result.requestCustomizationDelegate = requestCustomizationDelegate
        if #available(iOS 13.0, *) {
            result.noSSO = noSSO
        }
        return result
    }

    private static func extractAdditionalParams(_ config: [String: String]) -> [String: String]? {
        // Parse the additional parameters to be passed to the /authorization endpoint
        var configCopy = config
        
        // Remove "issuer", "clientId", "redirectUri", "scopes" and "logoutRedirectUri"
        configCopy.removeValue(forKey: "issuer")
        configCopy.removeValue(forKey: "clientId")
        configCopy.removeValue(forKey: "redirectUri")
        configCopy.removeValue(forKey: "scopes")
        configCopy.removeValue(forKey: "logoutRedirectUri")
        
        return configCopy
    }

    class RedirectBlockingURLSessionDelegate: NSObject, URLSessionTaskDelegate {
        
        static let shared = RedirectBlockingURLSessionDelegate()
        
        override private init() { super.init() }
    
        public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
            // prevent redirect
            completionHandler(nil)
        }
    }
}
