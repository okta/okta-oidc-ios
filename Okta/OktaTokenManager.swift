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

import AppAuth
import Vinculum

open class OktaTokenManager: NSObject, NSCoding {

    private var _idToken: String? = nil

    open var authState: OIDAuthState
    open var config: [String: String]
    open var accessibility: CFString

    open var idToken: String? {
        get { return self._idToken }
    }

    open var refreshToken: String? {
        get {
            guard let token = self.authState.refreshToken else { return nil }
            return token
        }
    }

    open var accessToken: String? {
        get {
            guard let token = self.authState.lastTokenResponse?.accessToken else { return nil }
            return token
        }
    }

    public init(authState: OIDAuthState, config: [String: String], accessibility: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly) {
        self.authState = authState
        self.config = config
        self.accessibility = accessibility

        super.init()

        // Since the idToken isn't stored in the last tokenResponse after refresh,
        // refer to the cached keychain version.
        if let prevIdToken = authState.lastTokenResponse?.idToken {
            self._idToken = prevIdToken
            try? Vinculum.set(key: "idToken", value: prevIdToken)
        } else {
            guard let prevIdToken = try? Vinculum.get("idToken")?.getString() else {
                self._idToken = nil
                return
            }
            self._idToken = prevIdToken
        }

        // Store the current configuration
        OktaAuth.configuration = config
    }

    required public convenience init?(coder decoder: NSCoder) {
        self.init(
                authState: decoder.decodeObject(forKey: "authState") as! OIDAuthState,
                   config: decoder.decodeObject(forKey: "config") as! [String: String],
            accessibility: (decoder.decodeObject(forKey: "accessibility") as! CFString)
        )
    }

    public func encode(with coder: NSCoder) {
        coder.encode(self.authState, forKey: "authState")
        coder.encode(self.config, forKey: "config")
        coder.encode(self.accessibility, forKey: "accessibility")
    }

    public func clear() {
        Vinculum.removeAll()
        OktaAuth.tokens = nil
    }
}
