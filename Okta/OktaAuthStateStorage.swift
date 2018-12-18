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

internal struct OktaAuthStateStorage {
    static let storageKey = "OktaAuthStateTokenManager"
    
    static func store(_ tokenManager: OktaTokenManager) {
        let authStateData = NSKeyedArchiver.archivedData(withRootObject: tokenManager)
        do {
            try OktaKeychain.set(key: self.storageKey, data: authStateData, accessibility: tokenManager.accessibility)
        } catch let error {
            print("Error: \(error)")
        }
    }
    
    static func getStoredState() -> OktaTokenManager? {
        guard let encodedAuthState: Data = try? OktaKeychain.get(key: self.storageKey) else {
            return nil
        }
    
        guard let storedState = NSKeyedUnarchiver
              .unarchiveObject(with: encodedAuthState) as? OktaTokenManager else {
            return nil
        }
        
        return storedState
    }
    
    static func clear() {
        do {
            try OktaKeychain.remove(key: self.storageKey)
        } catch let error {
            print("Error: \(error)")
        }
    }
}
