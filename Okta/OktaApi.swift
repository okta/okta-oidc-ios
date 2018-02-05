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

open class OktaApi: NSObject {
    class func post(_ url: URL, headers: [String: String]?,
                    postData: String?,
                    callback: @escaping ([String: Any]?, OktaError?) -> Void) {

        // Generic POST API wrapper

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.addValue(
            "okta-sdk-appauth-ios/\(VERSION) iOS/\(UIDevice.current.systemVersion)",
            forHTTPHeaderField: "X-Okta-User-Agent-Extended"
        )

        if let postBodyData = postData {
            request.httpBody = postBodyData.data(using: .utf8)
        }

        let task = URLSession.shared.dataTask(with: request){ data, response, error in
            if error != nil {
                callback(nil, .apiError(error: "\(String(describing: error?.localizedDescription))"))
                return
            }
            var responseJson = [String:Any]()
            try? responseJson = (JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any])!
            callback(responseJson, nil)
        }
        task.resume()
    }
}
