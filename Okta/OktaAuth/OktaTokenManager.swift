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

open class OktaTokenManager: NSObject, NSCoding {

    open var authState: OIDAuthState
    open var config: OktaAuthConfig
    open var accessibility: CFString

    open var accessToken: String? {
        // Return the known accessToken if it hasn't expired
        get {
            guard let tokenResponse = self.authState.lastTokenResponse,
                  let token = tokenResponse.accessToken,
                  let tokenExp = tokenResponse.accessTokenExpirationDate,
                  tokenExp.timeIntervalSince1970 > Date().timeIntervalSince1970 else {
                    return nil
            }
            return token
        }
    }

    open var idToken: String? {
        // Return the known idToken if it is valid
        get {
            guard let tokenResponse = self.authState.lastTokenResponse,
                let token = tokenResponse.idToken else {
                    return nil
            }
            do {
                // Attempt to validate the token
                let valid = try isValidToken(idToken: token)
                return valid ? token : nil
            } catch let error {
                // Capture the error here since we aren't throwing
                print(error)
                return nil
            }
        }
    }

    open var refreshToken: String? {
        // Return the known refreshToken
        get {
            guard let token = self.authState.refreshToken else { return nil }
            return token
        }
    }

    public init(authState: OIDAuthState, config: OktaAuthConfig, accessibility: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly) {
        self.authState = authState
        self.config = config
        self.accessibility = accessibility

        super.init()

        // Store the current configuration
        OktaAuth.configuration = config
    }

    required public convenience init?(coder decoder: NSCoder) {
        guard let configDict = decoder.decodeObject(forKey: "config") as? [String : String] else {
            return nil
        }
        
        guard let config = try? OktaAuthConfig(with: configDict) else {
            return nil
        }
        
        self.init(
            authState: decoder.decodeObject(forKey: "authState") as! OIDAuthState,
            config: config,
            accessibility: (decoder.decodeObject(forKey: "accessibility") as! CFString)
        )
    }

    public func encode(with coder: NSCoder) {
        coder.encode(self.authState, forKey: "authState")
        coder.encode(self.accessibility, forKey: "accessibility")
        coder.encode(self.config.toDictionary(), forKey: "config")
    }

    public func isValidToken(idToken: String?) throws -> Bool {
        guard let idToken = idToken,
            let tokenObject = OIDIDToken(idTokenString: idToken) else {
                throw OktaError.JWTDecodeError
        }
        
        if tokenObject.expiresAt.timeIntervalSinceNow < 0 {
            throw OktaError.JWTValidationError("ID Token expired")
        }
        
        return true
    }
    
    // Decodes the payload of a JWT
    public static func decodeJWT(_ token: String) throws -> [String: Any]? {
        let payload = token.split(separator: ".")
        guard payload.count > 1 else {
            return nil
        }
        
        var encodedPayload = "\(payload[1])"
        if encodedPayload.count % 4 != 0 {
            let padding = 4 - encodedPayload.count % 4
            encodedPayload += String(repeating: "=", count: padding)
        }

        guard let data = Data(base64Encoded: encodedPayload, options: []) else {
            throw OktaError.JWTDecodeError
        }
        
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        
        return jsonObject as? [String: Any]
    }

    public func clear() {
        OktaKeychain.clearAll()
        OktaAuth.tokenManager = nil
    }
}

extension OktaTokenManager {
    
    static let secureStorageKey = "OktaAuthStateTokenManager"

    class func readFromSecureStorage() -> OktaTokenManager? {
        guard let encodedAuthState: Data = try? OktaKeychain.get(key: secureStorageKey) else {
            return nil
        }

        guard let state = NSKeyedUnarchiver.unarchiveObject(with: encodedAuthState) as? OktaTokenManager else {
            return nil
        }

        return state
    }
    
    func writeToSecureStorage() {
        let authStateData = NSKeyedArchiver.archivedData(withRootObject: self)
        do {
            try OktaKeychain.set(
                key: OktaTokenManager.secureStorageKey,
                data: authStateData,
                accessibility: self.accessibility
            )
        } catch let error {
            print("Error: \(error)")
        }
    }
}

// Handles serialization of OktaAuthConfig.
// Needed as a temporary solution to omit changing the structre of serialized
// OktaTokenManager state.
// TODO: rework this approach in terms of OktaTokenManager refactoring.
private extension OktaAuthConfig {

    func toDictionary() -> [String:String] {
        var dict = [String:String]()
        
        dict["clientId"] = self.clientId
        dict["issuer"] = self.issuer
        dict["scopes"] = self.scopes
        dict["redirectUri"] = self.redirectUri.absoluteString
        dict["logoutRedirectUri"] = self.logoutRedirectUri?.absoluteString
        
        if let additionalParams = additionalParams {
            dict.merge(additionalParams) { (current, _) -> String in return current }
        }

        return dict
    }
}
