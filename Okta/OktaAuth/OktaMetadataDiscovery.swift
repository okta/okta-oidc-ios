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

class MetadataDiscovery: OktaAuthTask<OIDServiceConfiguration> {
    override func run(callback: @escaping (OIDServiceConfiguration?, OktaError?) -> Void) {
        guard let config = configuration else {
            callback(nil, OktaError.notConfigured)
            return
        }

        guard let issuer = config.issuer,
              let configUrl = URL(string: "\(issuer)/.well-known/openid-configuration") else {
              callback(nil, OktaError.noDiscoveryEndpoint)
              return
        }
        
        OktaApi.get(configUrl, headers: nil, onSuccess: { response in
            guard let dictResponse = response, let oidConfig = try? OIDServiceDiscovery(dictionary: dictResponse) else {
                callback(nil, OktaError.parseFailure)
                return
            }
            // Cache the well-known endpoint response
            OktaAuth.wellKnown = dictResponse

            callback(OIDServiceConfiguration(discoveryDocument: oidConfig), nil)
        }, onError: { error in
            let responseError =
                "Error returning discovery document: \(error.localizedDescription) Please" +
                "check your PList configuration"
            callback(nil, OktaError.APIError(responseError))
        })
    }
}
