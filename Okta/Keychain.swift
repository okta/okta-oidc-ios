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

public class Test {
    public func testfunc() {}
}

class KeychainItem: NSObject, NSCoding {
    public var key: String
    public var value: Data
    public var expiration: TimeInterval?
    public var accessGroup: String?
    public var accessibility: CFString
    
    init(key: String, value: Data, expiration: TimeInterval? = nil, accessGroup: String? = nil, accessibility: CFString? = nil) {
        self.key = key
        self.value = value
        self.expiration = expiration
        self.accessGroup = accessGroup
        self.accessibility = accessibility != nil ? accessibility! : kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    }
    
    required public convenience init?(coder decoder: NSCoder) {
        self.init(
            key: decoder.decodeObject(forKey: "key") as! String,
            value: decoder.decodeObject(forKey: "value") as! Data,
            expiration: decoder.decodeObject(forKey: "expiration") as? TimeInterval,
            accessGroup: decoder.decodeObject(forKey: "accessGroup") as? String,
            accessibility: (decoder.decodeObject(forKey: "accessibility") as! CFString)
        )
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(self.key, forKey: "key")
        coder.encode(self.value, forKey: "value")
        coder.encode(self.expiration, forKey: "expiration")
        coder.encode(self.accessGroup, forKey: "accessGroup")
        coder.encode(self.accessibility, forKey: "accessibility")
    }
    
    public func getString() -> String? {
        guard let item = String(data: self.value, encoding: .utf8) else {
            return nil
        }
        return item
    }
}

enum KeychainError: Error {
    case utf8EncodingError
    case failedToStore(Any)
    case failedToRetrieve(Any)
    case failedToDecode
    case failedToEncode(String)
    case failedToRemove(String)
}

extension KeychainError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .utf8EncodingError:
            return NSLocalizedString("Error converting data object to UTF8", comment: "")
        case .failedToStore(reason: let reason):
            return NSLocalizedString("Error storing to Keychain: \(reason)", comment: "")
        case .failedToRetrieve(reason: let reason):
            return NSLocalizedString("Error retrieving from Keychain: \(reason)", comment: "")
        case .failedToDecode:
            return NSLocalizedString("Error decoding keychain item", comment: "")
        case .failedToEncode(key: let key):
            return NSLocalizedString("Error encoding keychain item to Data type with key: \(key)", comment: "")
        case .failedToRemove(reason: let reason):
            return NSLocalizedString("Error removing keychain item: \(reason)", comment: "")
        }
    }
}


class Keychain: NSObject {
    class func set(key: String, value: String, expiration: TimeInterval? = nil, accessGroup: String? = nil, accessibility: CFString? = nil) throws {
        // Write a value (String) to the keychain
        guard let object = value.data(using: .utf8) else {
            throw KeychainError.utf8EncodingError
        }
        
        let item = KeychainItem(
            key: key,
            value: object,
            expiration: expiration,
            accessGroup: accessGroup,
            accessibility: accessibility
        )
        
        try writeToKeychain(item: item)
        
        if let seconds = item.expiration {
            buildTimeout(item.key, seconds)
        }
    }
    
    class func set(key: String, value: Data, expiration: TimeInterval? = nil, accessGroup: String? = nil, accessibility: CFString? = nil) throws {
        // Write a value (Data) to the keychain
        let item = KeychainItem(
            key: key,
            value: value,
            expiration: expiration,
            accessGroup: accessGroup,
            accessibility: accessibility
        )
        
        try writeToKeychain(item: item)
        
        if let seconds = item.expiration {
            buildTimeout(item.key, seconds)
        }
    }
    
    class func writeToKeychain(item: KeychainItem) throws {
        // Encode and store Keychain item
        let encodedItem = NSKeyedArchiver.archivedData(withRootObject: item)
        
        var q = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecValueData as String: encodedItem,
            kSecAttrAccount as String: item.key,
            kSecAttrAccessible as String: item.accessibility
            ] as [String : Any]
        
        if let accessGroup = item.accessGroup {
            // Access Group present
            q[kSecAttrAccessGroup as String] = accessGroup
        }
        
        // Delete existing (if applicable)
        SecItemDelete(q as CFDictionary)
        
        // Store to keychain
        let sanityCheck = SecItemAdd(q as CFDictionary, nil)
        if sanityCheck != noErr {
            throw KeychainError.failedToStore(sanityCheck.description)
        }
    }
    
    class func get(_ key: String) throws -> KeychainItem {
        // Return the keychain item as a string
        let q = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnData as String: kCFBooleanTrue,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccount as String: key,
            ] as CFDictionary
        
        var ref: AnyObject? = nil
        
        let sanityCheck = SecItemCopyMatching(q, &ref)
        
        if sanityCheck != noErr {
            throw KeychainError.failedToRetrieve(sanityCheck.description)
        }
        if let encodedItem = ref as? Data {
            guard let item = NSKeyedUnarchiver.unarchiveObject(with: encodedItem) as? KeychainItem else {
                throw KeychainError.failedToDecode
            }
            return item
        }
        throw KeychainError.failedToEncode(key)
    }
    
    class func remove(_ key: String) throws {
        let item = try self.get(key)
        
        let encodedItem = NSKeyedArchiver.archivedData(withRootObject: item)
        
        let q = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecValueData as String: encodedItem,
            kSecAttrAccount as String: item.key,
            kSecAttrAccessible as String: item.accessibility
            ] as [String : Any]
        
        // Delete existing (if applicable)
        let sanityCheck = SecItemDelete(q as CFDictionary)
        
        guard sanityCheck == errSecSuccess || sanityCheck == errSecItemNotFound else {
            throw KeychainError.failedToRemove(sanityCheck.description)
        }
    }
    
    class func removeAll() {
        // Remove all known keychain items
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
    
    class func buildTimeout(_ key: String, _ seconds: TimeInterval ) {
        // Deletes the item in the keychain after 'time'
        DispatchQueue.global().asyncAfter(deadline: .now() + seconds, execute : {
            guard let _ = try? remove(key) else {
                print("Failed removing \(key) from keychain.")
                return
            }
        })
    }
}
