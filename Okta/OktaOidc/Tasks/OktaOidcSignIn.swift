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

class OktaOidcSignInTask: OktaOidcTask<OIDAuthState>, OktaOidcUserSessionTask {

    var userAgentSession: OIDExternalUserAgentSession?

    override func run(callback: @escaping (OIDAuthState?, OktaOidcError?) -> Void) {
        OktaOidcMetadataDiscovery(config: config, oktaAPI: oktaAPI).run { oidConfig, error in
            guard let oidConfig = oidConfig else {
                callback(nil, error)
                return
            }

            var successRedirectURL: URL
            do {
                successRedirectURL = try self.redirectUri()
            } catch(let error) {
                //callback
                return
            }

            // Build the Authentication request
            let request = OIDAuthorizationRequest(
                       configuration: oidConfig,
                            clientId: self.config.clientId,
                              scopes: OktaOidcUtils.scrubScopes(self.config.scopes),
                              redirectURL: successRedirectURL,
                        responseType: OIDResponseTypeCode,
                additionalParameters: self.config.additionalParams
            )

            // Start the authorization flow
            self.userAgentSession = self.authStateWith(request: request, callback: callback)
        }
    }

    func redirectUri() throws -> URL {
        return config.redirectUri
    }

    func authStateWith(request: OIDAuthorizationRequest,
                       callback: @escaping (OIDAuthState?, OktaOidcError?) -> Void) -> OIDExternalUserAgentSession? {
        // override
        return nil
    }
}
