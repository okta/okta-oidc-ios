//
//  OktaKeychain.swift
//  Pods
//
//  Created by Jordan Melberg on 6/23/17.
//
//

import Foundation

public class OktaKeychain: NSObject {
    
    internal class func set(key: String, object: String) {
        let objectData = object.data(using: .utf8)

        let q = [
                     kSecClass as String: kSecClassGenericPassword as String,
                 kSecValueData as String: objectData!,
               kSecAttrAccount as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ] as CFDictionary
        
        // Delete existing (if applicable)
        SecItemDelete(q)
        
        // Store to keychain
        let sanityCheck = SecItemAdd(q, nil)
        if sanityCheck != noErr {
            print("Error Storing to Keychain: \(sanityCheck.description)")
        }
    }
    
    internal class func get(key: String) -> String? {
        let q = [
                     kSecClass as String: kSecClassGenericPassword,
                kSecReturnData as String: kCFBooleanTrue,
                kSecMatchLimit as String: kSecMatchLimitOne,
               kSecAttrAccount as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ] as CFDictionary
        
        var ref: AnyObject? = nil
        
        let sanityCheck = SecItemCopyMatching(q, &ref)

        if sanityCheck != noErr { return nil }
        
        if let parsedData = ref as? Data {
            return String(data: parsedData, encoding: .utf8)
        } else {
            print("Could not parse data as String")
        }
        return nil
    }
    
    internal class func removeAll() {
        let secClasses = [kSecClassGenericPassword]
        for secClass in secClasses {
            let q = [kSecClass as String: secClass]
            let sanityCheck = SecItemDelete(q as CFDictionary)
            if sanityCheck != noErr {
                print("Error deleting keychain item: \(sanityCheck.description)")
            }
        }
    }
}
