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

public struct Introspect {
    
    init() {}
    
    public func validate(_ token: String, callback: @escaping (Bool?, OktaError?) -> Void) {
        // Validate token by hitting the introspection endpoint
        
        if let introspectionEndpoint = getIntrospectionEndpoint() {
            // Build introspect request

            let headers = [
                      "Accept": "application/json",
                "Content-Type": "application/x-www-form-urlencoded"
            ]
            
            let data = "token=\(token)&client_id=\(OktaAuth.configuration?["clientId"] as! String)"
            
            OktaApi.post(introspectionEndpoint, headers: headers, postData: data) { response, error in callback(response?["active"] as? Bool, error) }
            
        } else {
            callback(nil, .error(error: "Error finding the introspection endpoint"))
        }
    }

    func getIntrospectionEndpoint() -> URL? {
        // Get the introspection endpoint from the discovery URL, or build it
        
        if let discoveryEndpoint = OktaAuth.tokens?.authState?.lastAuthorizationResponse.request.configuration.discoveryDocument?.discoveryDictionary["introspection_endpoint"] {
            return URL(string: discoveryEndpoint as! String)
        }
        
        if (OktaAuth.configuration?["issuer"] as! String).contains("oauth2") {
            // OAuth Authorization Server
            return URL(string: OktaAuth.configuration?["issuer"] as! String + "/v1/introspect")
        }
        
        return URL(string: OktaAuth.configuration?["issuer"] as! String + "/oauth2/v1/introspect")
        
        
    }
    
    public func withoutValidation(_ token: String, callback: @escaping (String?, OktaError?) -> Void) {
        // Decode token
        
        // Split JWT
        let jwt = token.components(separatedBy: ".")
        
        // Get claims
        var encodedClaims = jwt[1]
        
        if encodedClaims.characters.count % 4 != 0 {
            // Ensure encoded length is multiple of 4
            let paddingLength = 4 - encodedClaims.characters.count % 4
            encodedClaims += String(repeatElement("=", count: paddingLength))
        }
        
        if let claimData = Data(base64Encoded: encodedClaims, options: []),
            let decodedClaims = String(data:claimData, encoding: .utf8) {
            return callback(decodedClaims, nil)
        }
        return callback(nil, .error(error: "Could not decode token"))
    }
}
