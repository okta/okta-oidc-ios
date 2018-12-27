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
import Hydra

public struct SignIn {

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

    public func start(withDictConfig dict: [String: String], view: UIViewController) -> Promise<OktaTokenManager> {
        OktaAuth.configuration = dict
        return OktaAuthorization().authCodeFlow(dict, view)
    }

    public func start(withPListConfig plistName: String?, view: UIViewController) -> Promise<OktaTokenManager> {
        return Promise<OktaTokenManager>(in: .background, { resolve, reject, _ in
            guard let plist = plistName else {
                return reject(OktaError.noPListGiven)
            }

            if !self.passwordFlow {
                // Get client configuration from Okta.plist
                if let config = Utils.getPlistConfiguration(forResourceName: plist) {
                    OktaAuthorization().authCodeFlow(config, view)
                    .then { response in return resolve(response) }
                    .catch { error in return reject(error) }
                }
            }

            if self.passwordFlow {
                // Get client configuratin from Okta.plist
                if let config = Utils.getPlistConfiguration(forResourceName: plist) {
                    // Verify the ClientSecret was included
                    if config["clientSecret"] == "" {
                        reject(OktaError.noClientSecret(plist))
                    }

                    guard let username = self.username, let password = self.password else {
                        return reject(OktaError.noUserCredentials)
                    }

                    let credentials = ["username": username, "password": password]

                    OktaAuthorization().passwordFlow(config, credentials: credentials, view)
                    .then { response in return resolve(response) }
                    .catch { error in return reject(error) }
                }
            }
        })
    }

    public func start(_ view: UIViewController) -> Promise<OktaTokenManager> {
        return self.start(withPListConfig: "Okta", view: view)
    }
}
