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
import ApplicationServices

#if SWIFT_PACKAGE
@testable import OktaOidc_AppAuth
#endif

class OktaOidcBrowserTaskMAC: OktaOidcBrowserTask {

    var redirectServer: OktaRedirectServer?
    var redirectServerConfiguration: OktaRedirectServerConfiguration?
    var redirectURL: URL?
    var domainName: String?

    init(config: OktaOidcConfig,
         oktaAPI: OktaOidcHttpApiProtocol,
         redirectServerConfiguration: OktaRedirectServerConfiguration? = nil) {
        if let redirectServerConfiguration = redirectServerConfiguration {
            redirectServer = OktaRedirectServer(successURL: redirectServerConfiguration.successRedirectURL,
                                                port: redirectServerConfiguration.port ?? 0)
        }
        self.domainName = redirectServerConfiguration?.domainName
        self.redirectServerConfiguration = redirectServerConfiguration

        super.init(config: config, oktaAPI: oktaAPI)

        NSAppleEventManager.shared().setEventHandler(self,
                                                     andSelector: #selector(OktaOidcBrowserTaskMAC.handleEvent(_:withReplyEvent:)),
                                                     forEventClass: AEEventClass(kInternetEventClass),
                                                     andEventID: AEEventID(kAEGetURL))
    }

    deinit {
        redirectServer?.stopListener()
        NSAppleEventManager.shared().removeEventHandler(forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
    }

    override var userAgentSession: OKTExternalUserAgentSession? {
        didSet {
            self.redirectServer?.redirectHandler.currentAuthorizationFlow = userAgentSession
        }
    }

    override func signIn(delegate: OktaNetworkRequestCustomizationDelegate? = nil, validator: OKTTokenValidator, callback: @escaping ((OKTAuthState?, OktaOidcError?) -> Void)) {
        if let redirectServer = self.redirectServer {
            do {
                redirectURL = try redirectServer.startListener(with: domainName)
            } catch let error {
                callback(nil, OktaOidcError.redirectServerError("Redirect server error: \(error.localizedDescription)"))
                return
            }
        } else {
            redirectURL = self.config.redirectUri
        }

        super.signIn(validator: config.tokenValidator, callback: callback)
    }

    override func signOutWithIdToken(idToken: String, callback: @escaping (Void?, OktaOidcError?) -> Void) {
        if let redirectServer = self.redirectServer {
            do {
                redirectURL = try redirectServer.startListener(with: domainName)
            } catch let error {
                callback(nil, OktaOidcError.redirectServerError("Redirect server error: \(error.localizedDescription)"))
                return
            }
        } else {
            redirectURL = self.config.logoutRedirectUri
        }

        super.signOutWithIdToken(idToken: idToken, callback: callback)
    }

    override func signInRedirectUri() -> URL? {
        return redirectURL
    }

    override func signOutRedirectUri() -> URL? {
        return redirectURL
    }

    override func externalUserAgent() -> OKTExternalUserAgent? {
        return OKTExternalUserAgentMac()
    }
    
    @objc func handleEvent(_ event: NSAppleEventDescriptor!, withReplyEvent: NSAppleEventDescriptor!) {
        if let eventDescriptor = event.paramDescriptor(forKeyword: AEEventID(keyDirectObject)),
           let stringValue = eventDescriptor.stringValue,
           let url = URL(string: stringValue) {
                self.resume(with: url)
        }
    }
}

#endif
