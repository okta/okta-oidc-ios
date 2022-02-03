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

#if SWIFT_PACKAGE
import OktaOidc_AppAuth
#endif

open class OktaOidcStateManager: NSObject, NSSecureCoding {

    public static var supportsSecureCoding = true

    @objc open var authState: OKTAuthState
    @objc open var accessibility: CFString

    @objc public weak var requestCustomizationDelegate: OktaNetworkRequestCustomizationDelegate? {
        get {
            restAPI.requestCustomizationDelegate
        }
        set {
            restAPI.requestCustomizationDelegate = newValue
            authState.delegate = newValue
        }
    }
    
    @objc public var tokenValidator: OKTTokenValidator {
        get {
            authState.validator
        }
        set {
            authState.validator = newValue
        }
    }

    @objc open var accessToken: String? {
        // Return the known accessToken if it hasn't expired
        guard let tokenResponse = self.authState.lastTokenResponse,
              let token = tokenResponse.accessToken,
              let tokenExp = tokenResponse.accessTokenExpirationDate,
              !tokenValidator.isDateExpired(tokenExp, token: .access) else {
            return nil
        }
        
        return token
    }

    @objc open var idToken: String? {
        // Return the known idToken if it is valid
        guard let tokenResponse = self.authState.lastTokenResponse,
              let token = tokenResponse.idToken,
              validateToken(idToken: token) == nil else {
            return nil
        }
        
        return token
    }

    @objc open var refreshToken: String? {
        return self.authState.refreshToken
    }
    
    var restAPI: OktaOidcHttpApiProtocol = OktaOidcRestApi()

    @objc public init(authState: OKTAuthState,
                      accessibility: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly) {
        self.authState = authState
        self.accessibility = accessibility
        OktaOidcConfig.setupURLSession()
        
        super.init()
    }

    @objc public required convenience init?(coder decoder: NSCoder) {
        guard let state = decoder.decodeObject(forKey: "authState") as? OKTAuthState else {
            return nil
        }
        
        self.init(
            authState: state,
            accessibility: decoder.decodeObject(forKey: "accessibility") as! CFString // swiftlint:disable:this force_cast
        )
    }

    @objc public func encode(with coder: NSCoder) {
        coder.encode(self.authState, forKey: "authState")
        coder.encode(self.accessibility, forKey: "accessibility")
    }

    @objc public func validateToken(idToken: String?) -> Error? {
        guard let idToken = idToken,
            let tokenObject = OKTIDToken(idTokenString: idToken) else {
                return OktaOidcError.JWTDecodeError
        }
        
        if tokenValidator.isDateExpired(tokenObject.expiresAt, token: .id) {
            return OktaOidcError.JWTValidationError("ID Token expired")
        } else if tokenObject.expiresAt.timeIntervalSinceNow < 0 {
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
        authState.performAction { _, _, error in
            if let error = error {
                callback(nil, OktaOidcError.errorFetchingFreshTokens(error.localizedDescription))
                return
            }
            
            callback(self, nil)
        }
    }
    
    @objc public func introspect(token: String?, callback: @escaping ([String: Any]?, Error?) -> Void) {
        performRequest(to: .introspection, token: token, callback: callback)
    }

    @objc public func revoke(_ token: String?, callback: @escaping (Bool, Error?) -> Void) {
        performRequest(to: .revocation, token: token) { payload, error in
            if let error = error {
                callback(false, error)
                return
            }            

            // Token is considered to be revoked if there is no payload.
            callback(payload?.isEmpty ?? true, nil)
        }
    }

    @objc public func removeFromSecureStorage() throws {
        try OktaOidcKeychain.remove(key: self.clientId)
    }
    
    @available(*, deprecated, message: "This method deletes all keychain items accessible to an application. Use `removeFromSecureStorage` to remove Okta items.")
    @objc public func clear() {
        OktaOidcKeychain.clearAll()
    }
    
    @objc public func getUser(_ callback: @escaping ([String: Any]?, Error?) -> Void) {
        guard let token = accessToken else {
            DispatchQueue.main.async {
                callback(nil, OktaOidcError.noBearerToken)
            }
            return
        }

        let headers = ["Authorization": "Bearer \(token)"]
        
        performRequest(to: .userInfo, headers: headers, callback: callback)
    }
}

@objc public extension OktaOidcStateManager {

    @available(*, deprecated, message: "Please use readFromSecureStorage(for config: OktaOidcConfig) function")
    class func readFromSecureStorage() -> OktaOidcStateManager? {
        return readFromSecureStorage(forKey: "OktaAuthStateManager")
    }

    @objc class func readFromSecureStorage(for config: OktaOidcConfig) -> OktaOidcStateManager? {
        return readFromSecureStorage(forKey: config.clientId)
    }
    
    @objc func writeToSecureStorage() {
        let authStateData: Data
        do {
            if #available(iOS 11, OSX 10.14, *) {
                authStateData = try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
            } else {
                authStateData = NSKeyedArchiver.archivedData(withRootObject: self)
            }

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

        let state: OktaOidcStateManager?
        prepareKeyedArchiver()
      
        if #available(iOS 11, OSX 10.14, *) {
            state = (try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(encodedAuthState)) as? OktaOidcStateManager
        } else {
            state = NSKeyedUnarchiver.unarchiveObject(with: encodedAuthState) as? OktaOidcStateManager
        }

        return state
    }
  
    /// This method can be removed in the future with release 4.0.0 or higher.
    /// Resolves OKTA-427089
    private static func prepareKeyedArchiver() {
        let classes = [OKTAuthorizationRequest.self, OKTAuthorizationResponse.self,
                       OKTAuthState.self, OKTEndSessionRequest.self,
                       OKTEndSessionResponse.self, OKTRegistrationRequest.self,
                       OKTRegistrationResponse.self, OKTServiceConfiguration.self,
                       OKTServiceDiscovery.self, OKTTokenRequest.self,
                       OKTTokenResponse.self]
        
        for archivedClass in classes {
            let className = "\(archivedClass)".replacingOccurrences(of: "OKT", with: "OID")
            NSKeyedUnarchiver.setClass(archivedClass, forClassName: className)
        }
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

    func performRequest(to endpoint: OktaOidcEndpoint,
                        token: String?,
                        callback: @escaping ([String: Any]?, OktaOidcError?) -> Void) {
        guard let token = token else {
            DispatchQueue.main.async {
                callback(nil, OktaOidcError.noBearerToken)
            }
            return
        }
        
        let postString = "token=\(token)&client_id=\(clientId)"
        
        performRequest(to: endpoint, postString: postString, callback: callback)
    }
    
    func performRequest(to endpoint: OktaOidcEndpoint,
                        headers: [String: String]? = nil,
                        postString: String? = nil,
                        callback: @escaping ([String: Any]?, OktaOidcError?) -> Void) {
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
