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

// Okta Extension of OIDAuthorizationService
extension OIDAuthorizationService {

    static func perform(authRequest: OIDAuthorizationRequest, callback: @escaping OIDAuthorizationCallback) {
        var urlRequest = URLRequest(url: authRequest.externalUserAgentRequestURL())
        urlRequest.httpMethod = "GET"
        urlRequest.allHTTPHeaderFields = [
            "Accept": "application/json",
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        
        let session = OIDURLSessionProvider.session()
        session.dataTask(with: urlRequest) {(data, response, error) in
            guard let response = response as? HTTPURLResponse else {
                callback(nil, error)
                return
            }
            
            guard response.statusCode == 302,
                  let locationHeader = response.allHeaderFields["Location"] as? String,
                  let urlComonents = URLComponents(string: locationHeader),
                  let queryItems = urlComonents.queryItems else {
                    callback(nil, OktaOidcError.unexpectedAuthCodeResponse)
                    return
            }
        
            var parameters = [String : NSString]()
            queryItems.forEach({ item in
                parameters[item.name] = item.value as NSString?
            })

            if let allHeaderFields = response.allHeaderFields as? [String : String],
               let url = response.url {
                let httpCookies = HTTPCookie.cookies(withResponseHeaderFields: allHeaderFields, for: url)
                for cookie in httpCookies {
                    HTTPCookieStorage.shared.setCookie(cookie)
                }
            }

            let authResponse = OIDAuthorizationResponse(request: authRequest, parameters: parameters)
            callback(authResponse, error)
        }.resume()
    }
}
