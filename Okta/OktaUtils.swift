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

import Foundation

open class Utils: NSObject {

    open class func getPlistConfiguration() -> [String: Any]? {
        // Parse Okta.plist to build the authorization request
        
        return getPlistConfiguration(forResourceName: "Okta")
    }
    
    open class func getPlistConfiguration(forResourceName resourceName: String) -> [String: Any]? {
        // Parse Okta.plist to build the authorization request
        
        if let path = Bundle.main.url(forResource: resourceName, withExtension: "plist"),
            let data = try? Data(contentsOf: path) {
            if let result = try? PropertyListSerialization
                .propertyList(
                       from: data,
                    options: [],
                     format: nil
                ) as? [String: Any] {
                    // Validate PList info
                return self.validatePList(result)
            }
        }
        return nil
    }
    
    open class func validatePList(_ plist: [String: Any]?) -> [String: Any]? {
        // Perform validation on the PList fields
        // Currently only reformatting the issuer
        
        if plist == nil {
            return nil
        }
        
        var formatted = plist!
        
        if let issuer = formatted["issuer"] as? String {
            if let hasTrailingSlash = issuer.characters.last {
                // Return issuer without trailing slash
                var newIssuer = issuer
                formatted["issuer"] = hasTrailingSlash == "/" ? String(newIssuer.characters.dropLast()) : issuer
            }
        }
        OktaAuth.configuration = formatted
        return formatted
    }
    
    open class func scrubScopes(_ scopes: Any?) throws -> [String]{
        /**
         Perform scope scrubbing here.
         
         Verify that scopes:
            - Are in list format
            - Contain "openid"
        */
        
        var scrubbedScopes = [String]()
        if let listScopes = scopes as? [String] {
            // Scopes are formatted as list
            scrubbedScopes = listScopes
            if !listScopes.contains("openid") {
                scrubbedScopes.append("openid")
                print("WARNING: openID scope was not included. Adding 'openid' to request scopes.")
            }
            return scrubbedScopes
        }
        
        if let stringScopes = scopes as? String {
            // Scopes are forrmated as String
            scrubbedScopes = stringScopes.components(separatedBy: " ")
            if !scrubbedScopes.contains("openid") {
                scrubbedScopes.append("openid")
                print("WARNING: openID scope was not included. Adding 'openid' to request scopes.")
            }
            return scrubbedScopes
        }
        
        throw OktaError.error(error: "Scopes are in unspecified format. Must be an Array or String type.")
    }
    
    open class func base64URLDecode(_ input: String?) -> Data? {
        // Base64 URL Decodes a JWT component
        if input == nil { return nil }
        
        var base64 = input!
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let length = Double(base64.lengthOfBytes(using: .utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = requiredLength - length
        if paddingLength > 0 {
            let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
            base64 = base64 + padding
        }
        return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
    }
    
    open class func getDecodedString(_ value: String?) -> String? {
        // Returns the base64 decoded string value
        if value == nil { return nil }
        
        if let valueData = toBase64Data(string: value!),
            let decoded = String(data: valueData, encoding: .utf8) {
            return decoded
        }
        return nil
    }
    
    open class func toBase64Data(string: String) -> Data? {
        var rawString = string
        if rawString.characters.count % 4 != 0 {
            // Ensure encoded length is multiple of 4
            let paddingLength = 4 - rawString.characters.count % 4
            rawString += String(repeatElement("=", count: paddingLength))
        }
        
        if let encodedData = Data(base64Encoded: rawString, options: []) {
            return encodedData
        }
        return nil
    }
    
    open class func generateNonce() -> String {
        return UUID().uuidString
    }
}
