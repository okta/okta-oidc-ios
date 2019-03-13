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

class IntrospectTask: OktaAuthTask<[String : Any]> {
    
    let token: String?
    
    init(token: String?, config: OktaAuthConfig, oktaAPI: OktaHttpApiProtocol) {
        self.token = token
        super.init(config: config, oktaAPI: oktaAPI)
    }

    override func run(callback: @escaping ([String : Any]?, OktaError?) -> Void) {        
        guard let token = token else {
            callback(nil, OktaError.noBearerToken)
            return
        }

        guard let introspectionEndpoint = getIntrospectionEndpoint(config) else {
            callback(nil, OktaError.noIntrospectionEndpoint)
            return
        }

        let headers = [
            "Accept": "application/json",
            "Content-Type": "application/x-www-form-urlencoded"
        ]

        let data = "token=\(token)&client_id=\(config.clientId)"

        oktaAPI.post(introspectionEndpoint, headers: headers, postString: data, onSuccess: { response in
            callback(response, nil)
        }, onError: { error in
            callback(nil, error)
        })
    }

    func getIntrospectionEndpoint(_ config: OktaAuthConfig) -> URL? {
        // Get the introspection endpoint from the discovery URL, or build it
        if let introspectionEndpoint = OktaAuth.discoveredMetadata?["introspection_endpoint"] {
            return URL(string: introspectionEndpoint as! String)
        }

        let issuer = config.issuer
        if issuer.range(of: "oauth2") != nil {
            return URL(string: Utils.removeTrailingSlash(config.issuer) + "/v1/introspect")
        }
        return URL(string: Utils.removeTrailingSlash(config.issuer) + "/oauth2/v1/introspect")
    }
}
