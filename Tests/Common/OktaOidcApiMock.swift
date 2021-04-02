/*
 * Copyright (c) 2020-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

@testable import OktaOidc

class OktaOidcApiMock: OktaOidcHttpApiProtocol {

    weak var requestCustomizationDelegate: OktaNetworkRequestCustomizationDelegate?
    
    var lastRequest: URLRequest?
    
    var requestHandler: ((URLRequest, OktaOidcApiMock.OktaApiSuccessCallback, OktaOidcApiMock.OktaApiErrorCallback) -> Void)?
    
    func fireRequest(_ request: URLRequest,
                     onSuccess: @escaping OktaOidcApiMock.OktaApiSuccessCallback,
                     onError: @escaping OktaOidcApiMock.OktaApiErrorCallback) {
        lastRequest = request
        
        DispatchQueue.main.async { [weak self] in
            self?.requestHandler?(request, onSuccess, onError)
        }
    }
    
    func configure(error: OktaOidcError, requestValidationBlock: ((URLRequest) -> Void)? = nil) {
        requestHandler = { request, _, onError in
            requestValidationBlock?(request)
            onError(error)
        }
    }
    
     func configure(response: [String: Any]?, requestValidationBlock: ((URLRequest) -> Void)? = nil) {
        requestHandler = { request, onSuccess, _ in
            requestValidationBlock?(request)
            onSuccess(response)
        }
    }
}
