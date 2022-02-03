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

class OktaOidcRestApi: OktaOidcHttpApiProtocol {
    weak var requestCustomizationDelegate: OktaNetworkRequestCustomizationDelegate?
    
    func fireRequest(_ request: URLRequest,
                     onSuccess: @escaping OktaApiSuccessCallback,
                     onError: @escaping OktaApiErrorCallback) {
        let customizedRequest = requestCustomizationDelegate?.customizableURLRequest(request) ?? request
        let task = OKTURLSessionProvider.session().dataTask(with: customizedRequest) { data, response, error in
            self.requestCustomizationDelegate?.didReceive(response)
            guard let data = data,
                  error == nil,
                  let httpResponse = response as? HTTPURLResponse else {
                let errorMessage = error?.localizedDescription ?? "No response data"
                DispatchQueue.main.async {
                    onError(OktaOidcError.api(message: errorMessage, underlyingError: error))
                }
                return
            }

            guard 200 ..< 300 ~= httpResponse.statusCode else {
                DispatchQueue.main.async {
                    onError(OktaOidcError.api(message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode), underlyingError: nil))
                }
                return
            }

            let responseJson = (try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)) as? [String: Any]
            DispatchQueue.main.async {
                onSuccess(responseJson)
            }
        }
        task.resume()
    }
}
