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
import Hydra

internal class OktaApi: NSObject {

    class func post(_ url: URL, headers: [String: String]?, postString: String?) -> Promise<[String: Any]?> {
        // Generic POST API wrapper for data passed in as a String
        let data = postString != nil ? postString!.data(using: .utf8) : nil
        return OktaApi.post(url, headers: headers, postData: data)
    }

    class func post(_ url: URL, headers: [String: String]?, postJson: [String: Any]?) -> Promise<[String: Any]?> {
        // Generic POST API wrapper for data passed in as a JSON object [String: Any]
        let data = postJson != nil ? try? JSONSerialization.data(withJSONObject: postJson as Any, options: []) : nil
        return OktaApi.post(url, headers: headers, postData: data)
    }

    class func post(_ url: URL, headers: [String: String]?, postData: Data?) -> Promise<[String: Any]?> {
        // Generic POST API wrapper
        let request = self.setupRequest(url, method: "POST", headers: headers, body: postData)
        return self.fireRequest(request)
    }

    class func get(_ url: URL, headers: [String: String]?) -> Promise<[String: Any]?> {
        // Generic GET API wrapper
        let request = self.setupRequest(url, method: "GET", headers: headers)
        return self.fireRequest(request)
    }
    
    class func setupRequest(_ url: URL, method: String, headers: [String: String]?, body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = headers != nil ? headers : request.allHTTPHeaderFields
        request.addValue(
            "okta-sdk-appauth-ios/\(VERSION) iOS/\(UIDevice.current.systemVersion) Device/\(Utils.deviceModel())",
            forHTTPHeaderField: "User-Agent"
        )

        if let data = body {
            request.httpBody = data
        }

        return request
    }

    class func fireRequest(_ request: URLRequest) -> Promise<[String:Any]?> {
         return Promise<[String: Any]?>(in: .background, { resolve, reject, _ in
            let task = URLSession.shared.dataTask(with: request){ data, response, error in
                guard let data = data, error == nil else {
                    let errorMessage = error != nil ? error!.localizedDescription : "No response data"
                    return reject(OktaError.APIError(errorMessage))
                }
                let responseJson = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [String: Any]
                return resolve(responseJson)
            }
            task.resume()
        })
    }
}
