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
import Heimdall

open class OktaJWTValidator: NSObject {
    let jwt: OktaJWT
    
    init(_ token: OktaJWT) { self.jwt = token }
    
    func validateSignature(callback: @escaping (Bool?, OktaError?) -> Void) {
        // Okta base64 URL encodes the modulus and exponent values as part of the key
        // We need to decode them.
        
        getKeyForToken { response in
            if let key = response {
                // Get modulus and exponent from key
                let decodedModulus = Utils.base64URLDecode(key["n"] as? String)
                let decodedExponent = Utils.base64URLDecode(key["e"] as? String)
                
                if decodedModulus == nil || decodedExponent == nil {
                    callback(nil, .jwtValidationError(error: "Modulus or exponent from key could not be validated"))
                    return
                }
                
                // Create Heimdall component
                // This creates a public/private keypair based on the modulus and exponent.
                let signatureValidator = Heimdall(publicTag: "okta-appauth-sdk-keys", publicKeyModulus: decodedModulus!, publicKeyExponent: decodedExponent!)
                
                // Convert the encoded header and payload to Data
                let jwt = "\(self.jwt.encodedHeader).\(self.jwt.encodedPayload)".data(using: .utf8)
                
                // Base64 decode the signature for validation
                let base64DecodedSignature = Utils.base64URLDecode(self.jwt.encodedSignature)
                
                if jwt == nil || base64DecodedSignature == nil {
                    callback(nil, .jwtValidationError(error: "Error encoding/decoding JWT"))
                    return
                }
                
                // Call the validator
                // Returns true or false if signature is valid
                let isValid = signatureValidator?.verify(jwt!, signatureData: base64DecodedSignature!)
                signatureValidator?.destroy()
                callback(isValid, nil)
                return
            }
            callback(nil, .jwtValidationError(error: "No kid found for token"))
        }
    }
    
    func validate(callback: @escaping ([String: Any]?, OktaError?) -> Void) {
        // Performs steps to validate the idToken
        // Returns valid claims if token passes introspection
        
        // Validate the token's signature
        validateSignature {
            response, error in
            if error != nil || !(response!) {
                // Error while validating the signature or the id_token signature is invalid
                callback(nil, .jwtValidationError(error: "token signature is invalid"))
                return
            }
        }
        
        // Verify fields
        let dirtyClaimsString = Utils.getDecodedString(self.jwt.encodedPayload)?.data(using: .utf8)
        
        guard let dirtyClaims = getUnverifiedClaims(dirtyClaimsString) else {
            // Failed to decode claims
            callback(nil, .jwtValidationError(error: "Could not decode token claims"))
            return
        }
        
        if !validIssuer(dirtyClaims["iss"]) {
            callback(nil, .jwtValidationError(error: "Token issuer \(dirtyClaims["iss"] as! String) " +
                "does not match our issuer \(configuration!["issuer"] as! String)"))
            return
        }
        
        if !validAudience(dirtyClaims["aud"]) {
            callback(nil, .jwtValidationError(error: "Token aud \(dirtyClaims["aud"] as! String) " +
                "does not match our clientId \(configuration!["clientId"] as! String)"))
            return
        }
        
        if isExpired(dirtyClaims["exp"]) {
            // If the token expiration time has passed, the token must be revoked
            callback(nil, .jwtValidationError(error: "The JWT expired and is no longer valid"))
            return
        }
        
        if isIssuedInFuture(dirtyClaims["iat"]) {
            // The iat value indicates what time the token was "issued at".
            // We verify that this claim is valid by checking that the token was not
            // issued in the future, with some leeway for clock skew.
            callback(nil, .jwtValidationError(error: "The JWT was issued in the future"))
            return
        }
        
        if !validNonce(dirtyClaims["nonce"]) {
            // Verify the nonce value returned in the token matches the same one used in
            // the authorization request
            callback(nil, .jwtValidationError(error: "Invalid nonce"))
            return
        }
        
        // Return validated token claims
        callback(dirtyClaims, nil)
    }
    
    func getUnverifiedClaims(_ dirtyClaims: Data?) -> [String: Any]? {
        // Returns a dictionary of the unverified claims
        
        if dirtyClaims == nil { return nil }
        return try? JSONSerialization.jsonObject(with: dirtyClaims!, options: []) as! [String: Any]
    }
    
    public class func getKeys(callback: @escaping ([Any]?, OktaError?) -> Void) {
        // Return the keys from the /keys endpoint
        
        let jwksEndpoint = getKeysEndpoint()
        if jwksEndpoint == nil { callback(nil, .apiError(error: "Error finding the JWKS endpoint")) }
        
        // Call JWKS request
        OktaApi.get(jwksEndpoint!, headers: nil) {
            response, error in
            
            if let keys = response?["keys"] as? [Any] {
                callback(keys, nil)
                return
            }
            
            callback(nil, .error(error: "Error parsing keys from endpoint"))
        }
    }
    
    func getKeyForToken(callback: @escaping ([String: Any]?) -> Void) {
        // Returns the key matching the kid from the token
        
        OktaJWTValidator.getKeys {
            response, error in
            
            if error != nil { return }
            
            // Get KID from token
            if let kid = self.getKeyIdFromHeader() {
                callback(self.hasValidKey(response!, kid))
                return
            }
        }
    }
    
    func hasValidKey(_ keys: [Any], _ kid: String) -> [String: Any]? {
        // Checks to see if keys at the keys endpoint contain the same kid as the token header
        
        for key in keys {
            let keyDict = key as! [String: Any]
            let dirtyKid = keyDict["kid"] as! String
            if dirtyKid == kid {
                // Return the key
                return keyDict
            }
        }
        return nil
    }
    
    class func getKeysEndpoint() -> URL? {
        // Get the Keys endpoint from the discovery URL, or build it
        
        if let jwksUrl = OktaAuth.tokens?.authState?.lastAuthorizationResponse.request.configuration.discoveryDocument?.jwksURL {
            return jwksUrl
        }
        
        if (OktaAuth.configuration?["issuer"] as! String).contains("oauth2") {
            // OAuth Authorization Server
            return URL(string: OktaAuth.configuration?["issuer"] as! String + "/v1/keys")
        }
        
        return URL(string: OktaAuth.configuration?["issuer"] as! String + "/oauth2/v1/keys")
    }
    
    func getKeyIdFromHeader() -> String? {
        // Returns the KID from the token
        
        let headerString = Utils.getDecodedString(self.jwt.encodedHeader)
        if headerString == nil { return nil }
        
        let json = try? JSONSerialization.jsonObject(with: headerString!.data(using: .utf8)!, options: []) as! [String: Any]
        if let kid = json?["kid"] {
            // Return the kid from the header object
            return String(describing: kid)
        }
        return nil
    }
    
    func validIssuer(_ iss: Any?) -> Bool {
        // Returns true if the token issuer matches the configuration issuer
        if iss as! String == configuration!["issuer"] as! String { return true }
        return false
    }
    
    func validAudience(_ aud: Any?) -> Bool {
        // Returns true if the token audience matches the configuration audience
        
        if aud as! String == configuration!["clientId"] as! String { return true }
        return false
    }
    
    func isExpired(_ exp: Any?) -> Bool {
        let expiredDate = Date(timeIntervalSince1970: TimeInterval(exp as! NSNumber))
        let now = Date()
        
        // Allow 5 min clock skew for drift across servers
        let clockSkew = -300 as TimeInterval
        if (now.addingTimeInterval(clockSkew) > expiredDate) { return true }
        return false
    }
    
    func isIssuedInFuture(_ iat: Any?) -> Bool {
        let issuedAtDate = Date(timeIntervalSince1970: TimeInterval(iat as! NSNumber))
        let now = Date()
        
        // Allow 5 min clock skew for drift across servers
        let clockSkew = 300 as TimeInterval
        if (issuedAtDate > now.addingTimeInterval(clockSkew)) { return true }
        return false
    }
    
    func validNonce(_ nonce: Any?) -> Bool {
        if let tokenNonce = nonce as? String,  let authZRequest = tokens?.authState?.lastTokenResponse?.request.additionalParameters {
            return tokenNonce == authZRequest["nonce"]
        }
        return false
    }
}
