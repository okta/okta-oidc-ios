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

class OktaOidcSignInTaskMAC: OktaOidcSignInTask {

    private var redirectServer: OktaRedirectServer?

    init(config: OktaOidcConfig,
         oktaAPI: OktaOidcHttpApiProtocol,
         redirectServerConfiguration: OktaRedirectServerConfiguration? = nil) {
        if let redirectServerConfiguration = redirectServerConfiguration {
            redirectServer = OktaRedirectServer(successURL: redirectServerConfiguration.successRedirectURL,
                                                port: redirectServerConfiguration.port ?? 0)
        }
        super.init(config: config, oktaAPI: oktaAPI)
    }

    deinit {
        redirectServer?.stopListener()
    }

    override func redirectUri() throws -> URL {
        if let redirectServer = self.redirectServer {
            return try redirectServer.startListener()
        }

        return self.config.redirectUri
    }

    override func authStateWith(request: OIDAuthorizationRequest,
                       callback: @escaping (OIDAuthState?, OktaOidcError?) -> Void) -> OIDExternalUserAgentSession? {
        let externalUserAgent = OIDExternalUserAgentMac()
        let userAgentSession = OIDAuthState.authState(byPresenting: request, externalUserAgent: externalUserAgent) { authorizationResponse, error in
            
            defer { self.userAgentSession = nil }

            guard let authResponse = authorizationResponse else {
                return callback(nil, OktaOidcError.APIError("Authorization Error: \(error!.localizedDescription)"))
            }
            callback(authResponse, nil)
        }

        return userAgentSession
    }
}
