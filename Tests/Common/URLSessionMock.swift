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

// swiftlint:disable force_try
// swiftlint:disable force_cast
// swiftlint:disable force_unwrapping

import Foundation

class URLSessionDataTaskMock: URLSessionDataTask {
    private let completion: () -> Void

    init(completion: @escaping () -> Void) {
        self.completion = completion
    }

    override func resume() {
        completion()
    }
}

class URLSessionMock: URLSession {
    
    struct Response {
        var statusCode: Int = 200
        var headerFields: [String: String]?
        var data = Data()
    }

    var request: URLRequest?
    var responses: [Response]?
    
    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        self.request = request
        let responseData = responses?.removeFirst() ?? Response()
        
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: responseData.statusCode,
            httpVersion: nil,
            headerFields: responseData.headerFields
        )
        return URLSessionDataTaskMock() {
            completionHandler(responseData.data, response, nil)
        }
    }
}
