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

internal class UserInfoTask: OktaAuthTask<[String:Any]> {
    
    private let token: String?
    
    init(token: String?, config: OktaAuthConfig, oktaAPI: OktaHttpApiProtocol) {
        self.token = token
        super.init(config: config, oktaAPI: oktaAPI)
    }
    
    override func run(callback: @escaping ([String : Any]?, OktaError?) -> Void) {
        guard let userInfoEndpoint = OktaEndpoint.userInfo.getURL(issuer: self.config.issuer) else {
            callback(nil, .noUserInfoEndpoint)
            return
        }

        guard let token = token else {
            callback(nil, .noBearerToken)
            return
        }

        let headers = [
            "Accept": "application/json",
            "Content-Type": "application/x-www-form-urlencoded",
            "Authorization": "Bearer \(token)"
        ]

        oktaAPI.post(userInfoEndpoint, headers: headers, postData: nil,
            onSuccess: { response in callback(response, nil)},
            onError: { error in callback(nil, error) })
    }
}
