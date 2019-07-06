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

import UIKit

open class OktaOidcUtils: NSObject {

    internal class func scrubScopes(_ scopes: String?) -> [String]{
        /**
         Perform scope scrubbing here.

         Verify that scopes:
            - Are in string format separated by " "
            - Contain "openid"
        */
        var scrubbedScopes = [String]()

        if let stringScopes = scopes {
            // Scopes are formatted as a string
            scrubbedScopes = stringScopes.components(separatedBy: " ")
        }

        if !scrubbedScopes.contains("openid") {
            scrubbedScopes.append("openid")
            print("WARNING: openID scope was not included. Adding 'openid' to request scopes.")
        }

        return scrubbedScopes
    }

    internal class func removeTrailingSlash(_ val: String) -> String {
        // Removes the URLs trailing slash if it exists
        return String(val.suffix(1)) == "/" ? String(val.dropLast()) : val
    }
}
