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
    
    init(config: OktaAuthConfig?, token: String?) {
        self.token = token
        super.init(config: config)
    }
    
    override func run(callback: @escaping ([String : Any]?, OktaError?) -> Void) {
        guard let config = config else {
            callback(nil, OktaError.notConfigured)
            return
        }
        
        guard let userInfoEndpoint = getUserInfoEndpoint(config) else {
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

         authApi.post(userInfoEndpoint, headers: headers, postData: nil,
            onSuccess: { response in callback(response, nil)},
            onError: { error in callback(nil, error) })
    }

    func getUserInfoEndpoint(_ config: OktaAuthConfig) -> URL? {
        // Get the introspection endpoint from the discovery URL, or build it
        if let userInfoEndpoint = OktaAuth.wellKnown?["userinfo_endpoint"] {
            return URL(string: userInfoEndpoint as! String)
        }
        
        guard let issuer = config.issuer else {
            return nil
        }

        if issuer.range(of: "oauth2") != nil {
            return URL(string: Utils.removeTrailingSlash(issuer) + "/v1/userinfo")
        }
        return URL(string: Utils.removeTrailingSlash(issuer) + "/oauth2/v1/userinfo")
    }
}
