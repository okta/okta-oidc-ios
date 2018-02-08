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

open class Utils: NSObject {

    open class func getPlistConfiguration() -> [String: Any]? {
        // Parse Okta.plist to build the authorization request
        return getPlistConfiguration(forResourceName: "Okta")
    }

    open class func getPlistConfiguration(forResourceName resourceName: String) -> [String: Any]? {
        // Parse Okta.plist to build the authorization request

        if let path = Bundle.main.url(forResource: resourceName, withExtension: "plist"),
            let data = try? Data(contentsOf: path) {
            if let result = try? PropertyListSerialization
                .propertyList(
                       from: data,
                    options: [],
                     format: nil
                ) as? [String: Any] {
                    OktaAuth.configuration = result
                    return result
            }
        }
        return nil
    }

    internal class func scrubScopes(_ scopes: Any?) -> [String]{
        /**
         Perform scope scrubbing here.

         Verify that scopes:
            - Are in list format
            - Contain "openid"
        */

        var scrubbedScopes = [String]()

        if let stringScopes = scopes as? String {
            // Scopes are formatted as a string
            scrubbedScopes = stringScopes.components(separatedBy: " ")
        }

        if let arrayScopes = scopes as? [String] {
            scrubbedScopes = arrayScopes
        }

        if !scrubbedScopes.contains("openid") {
            scrubbedScopes.append("openid")
            print("WARNING: openID scope was not included. Adding 'openid' to request scopes.")
        }

        return scrubbedScopes
    }

    internal class func deviceModel() -> String {
        // Returns the device information
        var system = utsname()
        uname(&system)
        let model = withUnsafePointer(to: &system.machine.0) { ptr in
            return String(cString: ptr)
        }
        return model
    }

    internal class func removeTrailingSlash(_ val: String) -> String {
        // Removes the URLs trailing slash if it exists
        return String(val.suffix(1)) == "/" ? String(val.dropLast()) : val
    }
}
