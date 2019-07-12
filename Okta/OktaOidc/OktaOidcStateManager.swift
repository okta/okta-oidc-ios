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

open class OktaOidcStateManager: NSObject, NSCoding {

    @objc open var authState: OIDAuthState
    @objc open var accessibility: CFString

    @objc open var accessToken: String? {
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

    @objc open var idToken: String? {
        // Return the known idToken if it is valid
        get {
            guard let tokenResponse = self.authState.lastTokenResponse,
                let token = tokenResponse.idToken else {
                    return nil
            }

            if let _ = validateToken(idToken: token) {
                return nil
            }

            return token
        }
    }

    @objc open var refreshToken: String? {
        return self.authState.refreshToken
    }
    
    // Needed for UTs only. Entry point for mocking network calls.
    var restAPI: OktaOidcHttpApiProtocol = OktaOidcRestApi()

    @objc public init(authState: OIDAuthState, accessibility: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly) {
        self.authState = authState
        self.accessibility = accessibility

        super.init()
    }

    @objc required public convenience init?(coder decoder: NSCoder) {
        guard let state = decoder.decodeObject(forKey: "authState") as? OIDAuthState else {
            return nil
        }
        
        self.init(
            authState: state,
            accessibility: decoder.decodeObject(forKey: "accessibility") as! CFString
        )
    }

    @objc public func encode(with coder: NSCoder) {
        coder.encode(self.authState, forKey: "authState")
        coder.encode(self.accessibility, forKey: "accessibility")
    }

    @objc public func validateToken(idToken: String?) -> Error? {
        guard let idToken = idToken,
            let tokenObject = OIDIDToken(idTokenString: idToken) else {
                return OktaOidcError.JWTDecodeError
        }
        
        if tokenObject.expiresAt.timeIntervalSinceNow < 0 {
            return OktaOidcError.JWTValidationError("ID Token expired")
        }
        
        return nil
    }
    
    // Decodes the payload of a JWT
    @objc public static func decodeJWT(_ token: String) throws -> [String: Any] {
        let payload = token.split(separator: ".")
        guard payload.count > 1 else {
            return [:]
        }
        
        var encodedPayload = "\(payload[1])"
        if encodedPayload.count % 4 != 0 {
            let padding = 4 - encodedPayload.count % 4
            encodedPayload += String(repeating: "=", count: padding)
        }

        guard let data = Data(base64Encoded: encodedPayload, options: []) else {
            throw OktaOidcError.JWTDecodeError
        }
        
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        
        guard let result = jsonObject as? [String: Any] else {
            throw OktaOidcError.JWTDecodeError
        }
        
        return result
    }

    @objc public func renew(callback: @escaping ((OktaOidcStateManager?, Error?) -> Void)) {
        authState.setNeedsTokenRefresh()
        authState.performAction(freshTokens: { accessToken, idToken, error in
            if error != nil {
                callback(nil, OktaOidcError.errorFetchingFreshTokens(error!.localizedDescription))
                return
            }
            
            callback(self, nil)
        })
    }
    
    @objc public func introspect(token: String?, callback: @escaping ([String : Any]?, Error?) -> Void) {
        perfromRequest(to: .introspection, token: token, callback: callback)
    }

    @objc public func revoke(_ token: String?, callback: @escaping (Bool, Error?) -> Void) {
        perfromRequest(to: .revocation, token: token) { payload, error in
            if let error = error {
                callback(false, error)
                return
            }            

            // Token is considered to be revoked if there is no payload.
            callback(payload?.isEmpty ?? true , nil)
        }
    }

    @objc public func clear() {
        OktaOidcKeychain.clearAll()
    }
    
    @objc public func getUser(_ callback: @escaping ([String:Any]?, Error?) -> Void) {
        guard let token = accessToken else {
            DispatchQueue.main.async {
                callback(nil, OktaOidcError.noBearerToken)
            }
            return
        }

        let headers = ["Authorization": "Bearer \(token)"]
        
        perfromRequest(to: .userInfo, headers: headers, callback: callback)
    }
}

public extension OktaOidcStateManager {

    class func readFromSecureStorage() -> OktaOidcStateManager? {
        return readFromSecureStorage(forKey: "OktaAuthStateManager")
    }

    class func readFromSecureStorage(for config: OktaOidcConfig) -> OktaOidcStateManager? {
        return readFromSecureStorage(forKey: config.clientId)
    }
    
    func writeToSecureStorage() {
        let authStateData = NSKeyedArchiver.archivedData(withRootObject: self)
        do {
            try OktaOidcKeychain.set(
                key: self.clientId,
                data: authStateData,
                accessibility: self.accessibility
            )
        } catch let error {
            print("Error: \(error)")
        }
    }
    
    private class func readFromSecureStorage(forKey secureStorageKey: String) -> OktaOidcStateManager? {
        guard let encodedAuthState: Data = try? OktaOidcKeychain.get(key: secureStorageKey) else {
            return nil
        }

        guard let state = NSKeyedUnarchiver.unarchiveObject(with: encodedAuthState) as? OktaOidcStateManager else {
            return nil
        }

        return state
    }
}

internal extension OktaOidcStateManager {
    var discoveryDictionary: [String: Any]? {
        return authState.lastAuthorizationResponse.request.configuration.discoveryDocument?.discoveryDictionary
    }
}

private extension OktaOidcStateManager {
    var issuer: String? {
        return authState.lastAuthorizationResponse.request.configuration.issuer?.absoluteString
    }
    
    var clientId: String {
        return authState.lastAuthorizationResponse.request.clientID
    }

    
    func perfromRequest(to endpoint: OktaOidcEndpoint,
                        token: String?,
                        callback: @escaping ([String : Any]?, OktaOidcError?) -> Void) {
        guard let token = token else {
            DispatchQueue.main.async {
                callback(nil, OktaOidcError.noBearerToken)
            }
            return
        }
        
        let postString = "token=\(token)&client_id=\(clientId)"
        
        perfromRequest(to: endpoint, postString: postString, callback: callback)
    }
    
    func perfromRequest(to endpoint: OktaOidcEndpoint,
                        headers: [String: String]? = nil,
                        postString: String? = nil,
                        callback: @escaping ([String : Any]?, OktaOidcError?) -> Void) {
        guard let endpointURL = endpoint.getURL(discoveredMetadata: discoveryDictionary, issuer: issuer) else {
            DispatchQueue.main.async {
                callback(nil, endpoint.noEndpointError)
            }
            return
        }
        
        var requestHeaders = [
            "Accept": "application/json",
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        
        if let headers = headers {
            requestHeaders.merge(headers) { (_, new) in new }
        }

        restAPI.post(endpointURL, headers: requestHeaders, postString: postString, onSuccess: { response in
            callback(response, nil)
        }, onError: { error in
            callback(nil, error)
        })
    }
}
