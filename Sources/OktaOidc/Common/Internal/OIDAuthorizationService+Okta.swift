/*
 * Copyright (c) 2019-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

#if SWIFT_PACKAGE
import OktaOidc_AppAuth
#endif

// Okta Extension of OIDAuthorizationService
extension OKTAuthorizationService {

    static func perform(
        authRequest: OKTAuthorizationRequest,
        delegate: OktaNetworkRequestCustomizationDelegate? = nil,
        callback: @escaping OKTAuthorizationCallback
    ) {
        var urlRequest = URLRequest(url: authRequest.externalUserAgentRequestURL())
        urlRequest.httpMethod = "GET"
        urlRequest.allHTTPHeaderFields = [
            "Accept": "application/json",
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        let customizedRequest = delegate?.customizableURLRequest(urlRequest) ?? urlRequest

        let session = OKTURLSessionProvider.session()
        session.dataTask(with: customizedRequest) { [weak delegate] (_, response, error) in

            delegate?.didReceive(response)
            guard let response = response as? HTTPURLResponse else {
                callback(nil, OktaOidcError.api(message: "Authentication Error: No response", underlyingError: error))
                return
            }
            
            guard response.statusCode == 302 else {
                callback(nil, OktaOidcError.unexpectedAuthCodeResponse(statusCode: response.statusCode))
                return
            }
            
            guard let locationHeader = response.allHeaderFields["Location"] as? String,
                  let urlComponents = URLComponents(string: locationHeader),
                  let queryItems = urlComponents.queryItems else {
                      callback(nil, OktaOidcError.noLocationHeader)
                      return
                  }
        
            var parameters: [String: NSString] = [:]
            queryItems.forEach { item in
                parameters[item.name] = item.value as NSString?
            }
            
            let authResponse = OKTAuthorizationResponse(request: authRequest, parameters: parameters)
            
            setCookie(from: response)
            
            callback(authResponse, error)
        }.resume()
    }
    
    private static func setCookie(from response: HTTPURLResponse) {
        guard let allHeaderFields = response.allHeaderFields as? [String: String],
              let url = response.url else {
                  return
              }
        
        HTTPCookie.cookies(withResponseHeaderFields: allHeaderFields, for: url).forEach {
            HTTPCookieStorage.shared.setCookie($0)
        }
    }
}
