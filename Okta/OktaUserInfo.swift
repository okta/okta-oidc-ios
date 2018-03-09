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

internal struct UserInfo {

    init(token: String?, callback: @escaping ([String: Any]?, OktaError?) -> Void) {
        // Revoke the token
        guard let userInfoEndpoint = getUserInfoEndpoint() else {
            callback(nil, .NoUserInfoEndpoint)
            return
        }

        guard let token = token else {
            callback(nil, .NoBearerToken)
            return
        }

        let headers = [
            "Accept": "application/json",
            "Content-Type": "application/x-www-form-urlencoded",
            "Authorization": "Bearer \(token)"
        ]

        OktaApi.post(userInfoEndpoint, headers: headers, postData: nil)
        .then { response in callback(response, nil) }
        .catch { error in callback(nil, error as? OktaError) }
    }

    func getUserInfoEndpoint() -> URL? {
        // Get the introspection endpoint from the discovery URL, or build it
        if let userInfoEndpoint = OktaAuth.wellKnown?["userinfo_endpoint"] {
            return URL(string: userInfoEndpoint as! String)
        }

        let issuer = OktaAuth.configuration?["issuer"] as! String
        if issuer.range(of: "oauth2") != nil {
            return URL(string: Utils.removeTrailingSlash(issuer) + "/v1/userinfo")
        }
        return URL(string: Utils.removeTrailingSlash(issuer) + "/oauth2/v1/userinfo")
    }
}
