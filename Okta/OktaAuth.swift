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

import AppAuth
import SafariServices

public struct OktaAuthorization {

    func authCodeFlow(_ config: [String: Any], view: UIViewController,
                      callback: @escaping (OktaTokenManager?, OktaError?) -> Void) {
        // Discover Endpoints
        getMetadataConfig(URL(string: config["issuer"] as! String)) { oidConfig, error in
            if error != nil {
                return callback(nil, error!)
            }

            // Build the Authentication request
            let request = OIDAuthorizationRequest(
                       configuration: oidConfig!,
                            clientId: config["clientId"] as! String,
                              scopes: Utils.scrubScopes(config["scopes"]),
                         redirectURL: URL(string: config["redirectUri"] as! String)!,
                        responseType: OIDResponseTypeCode,
                additionalParameters: nil
            )

            // Start the authorization flow
            OktaAuth.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, presenting: view){
                authorizationResponse, error in
                
                if authorizationResponse != nil {
                    // Return the tokens
                    callback(OktaTokenManager(authState: authorizationResponse), nil)
                } else {
                    callback(nil, .apiError(error: "Authorization Error: \(error!.localizedDescription)"))
                }
            }
        }
    }

    func passwordFlow(_ config: [String: Any], credentials: [String: String]?, view: UIViewController,
                      callback: @escaping (OktaTokenManager?, OktaError?) -> Void) {
        // Discover Endpoints
        getMetadataConfig(URL(string: config["issuer"] as! String)) { oidConfig, error in
            if error != nil {
                return callback(nil, error!)
            }

            // Build the Authentication request
            let request = OIDTokenRequest(
                           configuration: oidConfig!,
                               grantType: OIDGrantTypePassword,
                       authorizationCode: nil,
                             redirectURL: URL(string: config["redirectUri"] as! String)!,
                                clientID: config["clientId"] as! String,
                            clientSecret: (config["clientSecret"] as! String),
                                   scope: Utils.scrubScopes(config["scopes"]).joined(separator: " "),
                            refreshToken: nil,
                            codeVerifier: nil,
                    additionalParameters: credentials
                )

            // Start the authorization flow
            OIDAuthorizationService.perform(request) { authorizationResponse, responseError in
                if responseError != nil {
                    callback(nil, .apiError(error: "Authorization Error: \(responseError!.localizedDescription)"))
                }

                if authorizationResponse != nil {
                    // Return the tokens
                    let authState = OIDAuthState(
                            authorizationResponse: nil,
                                    tokenResponse: authorizationResponse,
                             registrationResponse: nil
                        )
                    callback(OktaTokenManager(authState: authState), nil)
                }
            }
        }
    }
    
    // In the Future, when AppAuth supports the end session endpoint, this method will not be necessary anymore.
    func logoutFlow(_ config: [String: Any], view:UIViewController, callback: @escaping (OktaError?) -> Void) -> Any? {
        
        let configuration = OktaAuth.tokens?.authState?.lastAuthorizationResponse.request.configuration
        
        guard let endSessionEndpoint = configuration?.discoveryDocument?.discoveryDictionary["end_session_endpoint"] as? String else {
            callback(.apiError(error: "Error: failed to find the end session endpoint."))
            return nil
        }
        
        guard var endSessionURLComponents = URLComponents(string: endSessionEndpoint) else {
            callback(.apiError(error: "Error: Unable to parse End Session Endpoint"))
            return nil
        }
        
        guard let idToken = OktaAuth.tokens?.idToken else {
            callback(.apiError(error: "Error: Unable to get a valid ID Token"))
            return nil
        }
        
        var queryItems = [URLQueryItem(name: "id_token_hint", value: idToken)]
        var scheme:String?
        if let postLogoutRedirectUri = config["post_logout_redirect_uri"] as? String,
            let redirectURLComponents = URLComponents.init(string: postLogoutRedirectUri) {
            scheme = redirectURLComponents.scheme
            queryItems.append(URLQueryItem.init(name: "post_logout_redirect_uri", value: postLogoutRedirectUri))
        }
        endSessionURLComponents.queryItems = queryItems
        
        guard let url = endSessionURLComponents.url else {
            callback(.apiError(error: "Error: Unable to set End Session Endpoint parameters"))
            return nil
        }
        var logoutController:Any?
        if #available(iOS 11.0, *) {
            let session = SFAuthenticationSession(url: url, callbackURLScheme: scheme, completionHandler: { (_, _) in
                callback(nil)
            })
            session.start()
            logoutController = session
        } else {
            let safari = SFSafariViewController.init(url: url)
            view.present(safari, animated: true, completion: {
                callback(nil)
            })
            logoutController = safari
        }
        
        return logoutController
    }


    func getMetadataConfig(_ issuer: URL?, callback: @escaping (OIDServiceConfiguration?, OktaError?) -> Void) {
        // Get the metadata from the discovery endpoint
        guard let issuer = issuer, let configUrl = URL(string: "\(issuer)/.well-known/openid-configuration") else {
            return callback(nil, .error(error: "Could not determine discovery metadata endpoint"))
        }

        OktaApi.get(configUrl, headers: nil) { response, error in
            guard let dictResponse = response, let oidcConfig = try? OIDServiceDiscovery(dictionary: dictResponse) else {
                let responseError =
                    "Error returning discovery document:" +
                    "\(error!.localizedDescription) Please" +
                    "check your PList configuration"
                return callback(nil, .apiError(error: responseError))
            }
            return callback(OIDServiceConfiguration(discoveryDocument: oidcConfig), nil)
        }
    }
}
