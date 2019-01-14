/*
 * Copyright (c) 2019, Okta, Inc. and/or its affiliates. All rights reserved.
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

public struct Authorize {

    let sessionToken: String
    
    init(sessionToken: String){
        self.sessionToken = sessionToken
    }

    public func start(withDictConfig dict: [String: String]) -> Promise<OktaTokenManager> {
       return performAuthorize(withConfig: dict)
    }

    public func start(withPListConfig plistName: String?) -> Promise<OktaTokenManager> {
        return Promise<OktaTokenManager>(in: .background, { resolve, reject, _ in
            guard let plist = plistName else {
                return reject(OktaError.noPListGiven)
            }

            // Get client configuration from specified config
            if let config = Utils.getPlistConfiguration(forResourceName: plist) {
                self.performAuthorize(withConfig: config)
                .then { authState in resolve(authState) }
                .catch { error in reject(error) }
            }
        })
    }

    public func start() -> Promise<OktaTokenManager> {
        return self.start(withPListConfig: "Okta")
    }
    
    private func performAuthorize(withConfig config: [String: String]) -> Promise<OktaTokenManager> {
        return OktaAuthorization().authorize(withSessionToken: self.sessionToken, config: config)
    }
}
