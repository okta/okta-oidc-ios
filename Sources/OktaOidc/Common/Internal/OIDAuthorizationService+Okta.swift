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
        session.dataTask(with: customizedRequest) { [weak delegate] (data, response, error) in

            delegate?.didReceive(response)
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

            let authResponse = OKTAuthorizationResponse(request: authRequest, parameters: parameters)
            callback(authResponse, error)
        }.resume()
    }
}
