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

#if SWIFT_PACKAGE
import OktaOidc_AppAuth
#endif

protocol OktaOidcHttpApiProtocol {
    typealias OktaApiSuccessCallback = ([String: Any]?) -> Void
    typealias OktaApiErrorCallback = (OktaOidcError) -> Void

    var requestCustomizationDelegate: OktaNetworkRequestCustomizationDelegate? { get set }

    func post(_ url: URL,
              headers: [String: String]?,
              postString: String?,
              onSuccess: @escaping OktaApiSuccessCallback,
              onError: @escaping OktaApiErrorCallback)

    func post(_ url: URL,
              headers: [String: String]?,
              postJson: [String: Any]?,
              onSuccess: @escaping OktaApiSuccessCallback,
              onError: @escaping OktaApiErrorCallback)

    func post(_ url: URL,
              headers: [String: String]?,
              postData: Data?,
              onSuccess: @escaping OktaApiSuccessCallback,
              onError: @escaping OktaApiErrorCallback)

    func get(_ url: URL,
             headers: [String: String]?,
             onSuccess: @escaping OktaApiSuccessCallback,
             onError: @escaping OktaApiErrorCallback)

    func fireRequest(_ request: URLRequest,
                     onSuccess: @escaping OktaApiSuccessCallback,
                     onError: @escaping OktaApiErrorCallback)
}

extension OktaOidcHttpApiProtocol {
    func post(_ url: URL,
              headers: [String: String]?,
              postString: String?,
              onSuccess: @escaping OktaApiSuccessCallback,
              onError: @escaping OktaApiErrorCallback) {
        // Generic POST API wrapper for data passed in as a String
        let data = postString?.data(using: .utf8)
        return self.post(url, headers: headers, postData: data, onSuccess: onSuccess, onError: onError)
    }

    func post(_ url: URL,
              headers: [String: String]?,
              postJson: [String: Any]?,
              onSuccess: @escaping OktaApiSuccessCallback,
              onError: @escaping OktaApiErrorCallback) {
        // Generic POST API wrapper for data passed in as a JSON object [String: Any]
        let data = postJson != nil ? try? JSONSerialization.data(withJSONObject: postJson as Any, options: []) : nil
        return self.post(url, headers: headers, postData: data, onSuccess: onSuccess, onError: onError)
    }

    func post(_ url: URL,
              headers: [String: String]?,
              postData: Data?,
              onSuccess: @escaping OktaApiSuccessCallback,
              onError: @escaping OktaApiErrorCallback) {
        // Generic POST API wrapper
        let request = self.setupRequest(url, method: "POST", headers: headers, body: postData)
        return self.fireRequest(request, onSuccess: onSuccess, onError: onError)
    }

    func get(_ url: URL,
             headers: [String: String]?,
             onSuccess: @escaping OktaApiSuccessCallback,
             onError: @escaping OktaApiErrorCallback) {
        // Generic GET API wrapper
        let request = self.setupRequest(url, method: "GET", headers: headers)
        return self.fireRequest(request, onSuccess: onSuccess, onError: onError)
    }
    
    func setupRequest(_ url: URL,
                      method: String,
                      headers: [String: String]?,
                      body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = headers ?? request.allHTTPHeaderFields
        request.addValue(OktaUserAgent.userAgentHeaderValue(), forHTTPHeaderField: OktaUserAgent.userAgentHeaderKey())

        if let data = body {
            request.httpBody = data
        }

        return request
    }
}
