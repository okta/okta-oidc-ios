/*
 * Copyright (c) 2018-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

public struct Logout {
    private let idToken: String?
    
    init(idToken: String?) {
        self.idToken = idToken
    }
    
    public func start(withDictConfig dict: [String: String], view: UIViewController) -> Promise<Void> {
        return Promise<Void>(in: .background, { resolve, reject, _ in
            guard let idToken = self.idToken else {
                return reject(OktaError.missingIdToken)
            }
            
            OktaAuthorization().logout(dict, idToken: idToken, view: view)
                .then { _ in return resolve(()) }
                .catch { error in return reject(error) }
        })
    }
    
    public func start(withPListConfig plistName: String?, view: UIViewController) -> Promise<Void> {
        return Promise<Void>(in: .background, { resolve, reject, _ in
            guard let plist = plistName,
                let config = Utils.getPlistConfiguration(forResourceName: plist) else {
                    return reject(OktaError.noPListGiven)
            }
            
            self.start(withDictConfig: config, view: view)
            .then { _ in return resolve(()) }
            .catch { error in return reject(error) }
        })
    }
    
    public func start(_ view: UIViewController) -> Promise<Void> {
        return start(withPListConfig: "Okta", view: view)
    }
}
