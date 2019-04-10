/*
 * Copyright (c) 2018, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

enum OktaOidcKeychainError: Error {
    case codingError
    case failed(String)
    case notFound
}

class OktaOidcKeychain: NSObject {

    /**
     Stores an item securely in the Keychain.
     - parameters:
     - key: Hash to reference the stored Keychain item
     - string: String to store inside of the keychain
     */
    class func set(key: String, string: String, accessGroup: String? = nil, accessibility: CFString? = nil) throws {
        guard let objectData = string.data(using: .utf8) else {
            throw OktaOidcKeychainError.codingError
        }
        try set(key: key, data: objectData, accessGroup: accessGroup, accessibility: accessibility)
    }
    
    /**
     Stores an item securely in the Keychain.
     - parameters:
     - key: Hash to reference the stored Keychain item
     - data: Data to store inside of the keychain
     */
    class func set(key: String, data: Data, accessGroup: String? = nil, accessibility: CFString? = nil) throws {
        var q = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecValueData as String: data,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: accessibility ?? kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ] as [String : Any]
        
        if let accessGroup = accessGroup {
            q[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let cfDictionary = q as CFDictionary
        // Delete existing (if applicable)
        SecItemDelete(cfDictionary)
        
        let sanityCheck = SecItemAdd(cfDictionary, nil)
        if sanityCheck != noErr {
            throw OktaOidcKeychainError.failed(sanityCheck.description)
        }        
    }
    
    /**
     Retrieve the stored JWK information from the Keychain.
     - parameters:
     - key: Hash to reference the stored Keychain item
     */
    class func get(key: String) throws -> String {
        let data: Data = try get(key: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw OktaOidcKeychainError.codingError
        }
        return string
    }
    
    /**
     Retrieve the stored JWK information from the Keychain.
     - parameters:
     - key: Hash to reference the stored Keychain item
     */
    class func get(key: String) throws -> Data {
        let q = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnData as String: kCFBooleanTrue,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccount as String: key
        ] as CFDictionary
        
        var ref: AnyObject? = nil
        
        let sanityCheck = SecItemCopyMatching(q, &ref)
        guard sanityCheck == noErr else {
            if sanityCheck == errSecItemNotFound {
                throw OktaOidcKeychainError.notFound
            } else {
                throw OktaOidcKeychainError.failed(sanityCheck.description)
            }
        }
        guard let data = ref as? Data else {
            throw OktaOidcKeychainError.failed("No data for \(key)")
        }
        return data
    }
    
    /**
     Remove the stored JWK information from the Keychain.
     - parameters:
     - key: Hash to reference the stored Keychain item
     */
    class func remove(key: String) throws {
        let data: Data = try get(key: key)
        let q = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecValueData as String: data,
            kSecAttrAccount as String: key
        ] as CFDictionary
        
        // Delete existing (if applicable)
        let sanityCheck = SecItemDelete(q)
        guard sanityCheck == noErr else {
            throw OktaOidcKeychainError.failed(sanityCheck.description)
        }
    }
    
    /**
     Removes all entities from the Keychain.
     */
    class func clearAll() {
        let secItemClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]
        
        for secItemClass in secItemClasses {
            let dictionary = [ kSecClass as String:secItemClass ] as CFDictionary
            SecItemDelete(dictionary)
        }
    }
}
