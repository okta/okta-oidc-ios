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

class OktaOidcMetadataDiscovery: OktaOidcTask<OIDServiceConfiguration> {

    override func run(callback: @escaping (OIDServiceConfiguration?, OktaOidcError?) -> Void) {
        guard let configUrl = URL(string: "\(config.issuer)/.well-known/openid-configuration") else {
            DispatchQueue.main.async {
                callback(nil, OktaOidcError.noDiscoveryEndpoint)
            }
            return
        }

        oktaAPI.get(configUrl, headers: nil, onSuccess: { response in
            guard let dictResponse = response, let oidConfig = try? OIDServiceDiscovery(dictionary: dictResponse) else {
                callback(nil, OktaOidcError.parseFailure)
                return
            }

            callback(OIDServiceConfiguration(discoveryDocument: oidConfig), nil)
        }, onError: { error in
            let responseError =
                "Error returning discovery document: \(error.localizedDescription). Please" +
                " check your PList configuration"
            callback(nil, OktaOidcError.APIError(responseError))
        })
    }
}
