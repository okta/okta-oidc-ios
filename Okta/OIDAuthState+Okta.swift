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
import Hydra
import OktaAppAuth

// Okta Extension of OIDAuthState
extension OIDAuthState {

    static func getState(withAuthRequest authRequest: OIDAuthorizationRequest) -> Promise<OIDAuthState> {
        return Promise<OIDAuthState>(in: .background, { resolve, reject, _ in
            // setup custom URL session
            self.setupURLSession()

            // Make authCode request
            OIDAuthorizationService.perform(authRequest: authRequest, callback: { authResponse, error in
                guard let authResponse = authResponse else {
                    return reject(OktaError.APIError("Authorization Error: \(error!.localizedDescription)"))
                }

                guard let _ = authResponse.authorizationCode,
                      let tokenRequest = authResponse.tokenExchangeRequest() else {
                        return reject(OktaError.unableToGetAuthCode)
                }

                // Make token request
                OIDAuthorizationService.perform(tokenRequest, originalAuthorizationResponse: authResponse, callback:
                { tokenResponse, error in
                    guard let tokenResponse = tokenResponse else {
                        return reject(OktaError.APIError("Authorization Error: \(error!.localizedDescription)"))
                    }

                    let authState = OIDAuthState(authorizationResponse: authResponse, tokenResponse: tokenResponse)
                    return resolve(authState)
                })
            })
        })
        .always {
            // Restore default URL session
            self.restoreURLSession()
        }
    }
    
    private static func setupURLSession() {
        /*
         Setup auth session to block redirection because authorization request
         implies redirection and passing authCode as a query parameter.
        */
        let config = URLSessionConfiguration.default
        config.httpShouldSetCookies = false

        let session = URLSession(
            configuration: config,
            delegate: RedirectBlockingURLSessionDelegate.shared,
            delegateQueue: .main)
        
        OIDURLSessionProvider.setSession(session)
    }
    
    private static func restoreURLSession() {
        OIDURLSessionProvider.setSession(URLSession.shared)
    }
    
    private class RedirectBlockingURLSessionDelegate: NSObject, URLSessionTaskDelegate {
        
        static let shared = RedirectBlockingURLSessionDelegate()
        
        private override init() { super.init() }
    
        public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
            // prevent redirect
            completionHandler(nil)
        }
    }
}
