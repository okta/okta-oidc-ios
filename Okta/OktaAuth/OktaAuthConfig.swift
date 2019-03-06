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

public struct OktaAuthConfig: Codable {
    public static let defaultPlistName = "Okta"
    
    public let clientId: String?
    public let issuer: String?
    public let scopes: String?
    public let redirectUri: URL?
    public let logoutRedirectUri: URL?
    
    public let additionalParams: [String:String]?
     
    public static func `default`() throws -> OktaAuthConfig {
        return try OktaAuthConfig(fromPlist: defaultPlistName)
    }
     
    public init(with dict: [String: String]) {
        clientId = dict["clientId"]
        issuer = dict["issuer"]
        scopes = dict["scopes"]
        
        if let redirectUriString = dict["redirectUri"] {
            redirectUri = URL(string: redirectUriString)
        } else {
            redirectUri = nil
        }
        
        if let logoutRedirectUriString = dict["logoutRedirectUri"] {
            logoutRedirectUri = URL(string: logoutRedirectUriString)
        } else {
            logoutRedirectUri = nil
        }
        
        additionalParams = OktaAuthConfig.parseAdditionalParams(dict)
    }
     
    public init(fromPlist plistName: String) throws {
        guard let path = Bundle.main.url(forResource: plistName, withExtension: "plist") else {
            throw OktaError.noPListGiven
        }
        
        guard let data = try? Data(contentsOf: path),
            let plistContent = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
            let configDict = plistContent as? [String: String] else {
                throw OktaError.pListParseFailure
        }
        
        self.init(with: configDict)
    }
    
    private static func parseAdditionalParams(_ config: [String: String]) -> [String: String]? {
        // Parse the additional parameters to be passed to the /authorization endpoint
        var configCopy = config
        
        // Remove "issuer", "clientId", "redirectUri", and "scopes"
        configCopy.removeValue(forKey: "issuer")
        configCopy.removeValue(forKey: "clientId")
        configCopy.removeValue(forKey: "redirectUri")
        configCopy.removeValue(forKey: "scopes")
        configCopy.removeValue(forKey: "logoutRedirectUri")
        
        return configCopy
    }
}

extension OktaAuthConfig: Equatable {
    public static func == (lhs: OktaAuthConfig, rhs: OktaAuthConfig) -> Bool {
        return lhs.clientId == rhs.clientId &&
               lhs.issuer == rhs.issuer &&
               lhs.scopes == rhs.scopes &&
               lhs.redirectUri == rhs.redirectUri &&
               lhs.logoutRedirectUri == rhs.logoutRedirectUri &&
               lhs.additionalParams == rhs.additionalParams
    }
}
