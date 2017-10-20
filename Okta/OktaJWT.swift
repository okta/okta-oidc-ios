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

import Foundation

open class OktaJWT {
    var token: String
    var encodedHeader: String
    var encodedPayload: String
    var encodedSignature: String
    
    init(token: String?) throws {
        // Check to make sure the format of the token is correct
        if let jwt = token?.components(separatedBy: ".") {
            if jwt.count == 3 {
                // Store the base64 encoded elements of the token
                self.encodedHeader = jwt[0]
                self.encodedPayload = jwt[1]
                self.encodedSignature = jwt[2]
                self.token = token!
                return
            }
        }
        throw OktaError.jwtValidationError(error: "Token provided is not formatted as a JWT")
    }
}
