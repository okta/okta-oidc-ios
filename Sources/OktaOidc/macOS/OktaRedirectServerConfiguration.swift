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

#if os(macOS)

import Foundation

public class OktaRedirectServerConfiguration: NSObject {
    public var port: UInt16?
    public var successRedirectURL: URL?
    public var domainName: String?

    public init(successRedirectURL: URL?, port: UInt16?, domainName: String?) {
        self.successRedirectURL = successRedirectURL
        self.port = port
        self.domainName = domainName
    }

    public static var `default`: OktaRedirectServerConfiguration {
        let configuration = OktaRedirectServerConfiguration(successRedirectURL: URL(string: "http://openid.github.io/AppAuth-iOS/redirect/"),
                                                            port: nil,
                                                            domainName: nil)
        return configuration
    }
}

#endif
