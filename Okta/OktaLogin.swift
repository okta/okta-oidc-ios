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

public struct Login {
    
    var username, password: String?
    var passwordFlow = false

    init(forUsername username: String, forPassword password: String){
        // Login via Username/Password
        self.username = username
        self.password = password
        
        self.passwordFlow = true
    }

    init(){
        // Login via Authoriation Code Flow
        self.username = nil
        self.password = nil

        self.passwordFlow = false
    }

    public func start(withPListConfig plistName: String?, view: UIViewController,
                      callback: @escaping (OktaTokenManager?, OktaError?) -> Void) {

        if plistName == nil {
            callback(nil, .NoPListGiven)
            return
        }

        if !self.passwordFlow {
            // Get client configuration from Okta.plist
            if let config = Utils.getPlistConfiguration(forResourceName: plistName!) {
                OktaAuthorization().authCodeFlow(config, view: view) { response, error in callback(response, error) }
            }
        }

        if self.passwordFlow {
            // Get client configuratin from Okta.plist
            if let config = Utils.getPlistConfiguration(forResourceName: plistName!) {
                // Verify the ClientSecret was included
                if (config["clientSecret"] as! String) == "" {
                    callback(nil, .NoClientSecret(plistName!))
                    return
                }
                if self.username == nil || self.password == nil {
                    callback(nil, .NoUserCredentials)
                    return
                }

                let credentials = [
                    "username": self.username!,
                    "password": self.password!
                ]

                OktaAuthorization().passwordFlow(config, credentials: credentials, view: view) { response, error in callback(response, error) }
            }
        }
    }

    public func start(_ view: UIViewController, callback: @escaping (OktaTokenManager?, OktaError?) -> Void) {
        self.start(withPListConfig: "Okta", view: view) { result, error in callback(result, error) }
    }
}
