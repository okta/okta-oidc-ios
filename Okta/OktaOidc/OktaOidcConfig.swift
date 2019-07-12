/*
 * Copyright (c) 2019, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

public class OktaOidcConfig: NSObject, Codable {
    @objc public static let defaultPlistName = "Okta"
    
    @objc public let clientId: String
    @objc public let issuer: String
    @objc public let scopes: String
    @objc public let redirectUri: URL
    @objc public let logoutRedirectUri: URL?
    
    @objc public let additionalParams: [String:String]?

    @objc public static func `default`() throws -> OktaOidcConfig {
        return try OktaOidcConfig(fromPlist: defaultPlistName)
    }

    @objc public init(with dict: [String: String]) throws {
        guard let clientId = dict["clientId"], clientId.count > 0,
              let issuer = dict["issuer"], let _ = URL(string: issuer),
              let scopes = dict["scopes"], scopes.count > 0,
              let redirectUriString = dict["redirectUri"],
              let redirectUri = URL(string: redirectUriString) else {
                throw OktaOidcError.missingConfigurationValues
        }
        
        self.clientId = clientId
        self.issuer = issuer
        self.scopes = scopes
        self.redirectUri = redirectUri
        
        if  let logoutRedirectUriString = dict["logoutRedirectUri"] {
            logoutRedirectUri = URL(string: logoutRedirectUriString)
        } else {
            logoutRedirectUri = nil
        }
        
        additionalParams = OktaOidcConfig.extractAdditionalParams(dict)
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
    
    override public func isEqual(_ object: Any?) -> Bool {
        guard let config = object as? OktaOidcConfig else {
            return false
        }
        return self.clientId == config.clientId &&
               self.issuer == config.issuer &&
               self.scopes == config.scopes &&
               self.redirectUri == config.redirectUri &&
               self.logoutRedirectUri == config.logoutRedirectUri &&
               self.additionalParams == config.additionalParams
    }
}
