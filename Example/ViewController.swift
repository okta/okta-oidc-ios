/*
 * Copyright (c) 2019-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import OktaOidc
import UIKit

// swiftlint:disable force_try
// swiftlint:disable force_cast
// swiftlint:disable force_unwrapping

// swiftlint:disable force_try
// swiftlint:disable force_cast
// swiftlint:disable force_unwrapping

final class ViewController: UIViewController {

    @IBOutlet private weak var tokenView: UITextView!
    @IBOutlet private weak var signInButton: UIButton!
    
    private var oktaAppAuth: OktaOidc?
    private var authStateManager: OktaOidcStateManager? {
        didSet {
            authStateManager?.writeToSecureStorage()
        }
    }
    
    private var isUITest: Bool {
        return ProcessInfo.processInfo.environment["UITEST"] == "1"
    }
    
    private var testConfig: OktaOidcConfig? {
        return try? OktaOidcConfig(with: [
            "issuer": ProcessInfo.processInfo.environment["ISSUER"]!,
            "clientId": ProcessInfo.processInfo.environment["CLIENT_ID"]!,
            "redirectUri": ProcessInfo.processInfo.environment["REDIRECT_URI"]!,
            "logoutRedirectUri": ProcessInfo.processInfo.environment["LOGOUT_REDIRECT_URI"]!,
            "scopes": "openid profile offline_access"
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let configuration = try? OktaOidcConfig.default()
        configuration?.requestCustomizationDelegate = self
        
        configuration?.tokenValidator = self
        
        oktaAppAuth = try? OktaOidc(configuration: isUITest ? testConfig : configuration)
        AppDelegate.shared.oktaOidc = oktaAppAuth
        if let config = oktaAppAuth?.configuration {
            authStateManager = OktaOidcStateManager.readFromSecureStorage(for: config)
            authStateManager?.requestCustomizationDelegate = self
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard oktaAppAuth != nil else {
            self.showMessage("SDK is not configured!")
            return
        }
        
        self.buildTokenTextView()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let authViewController = segue.destination as? AuthViewController else {
            return
        }
        
        authViewController.oktaAppAuth = oktaAppAuth
        authViewController.onAuthenticated = { [weak self] authStateManager in
            self?.authStateManager = authStateManager
        }
    }

    @IBAction func signInButton(_ sender: Any) {
        self.signInWithBrowser()
    }
    
    @IBAction func signOutButton(_ sender: Any) {
        self.signOut()
    }

    @IBAction func clearTokens(_ sender: Any) {
        try? authStateManager?.removeFromSecureStorage()
        authStateManager = nil
        
        self.buildTokenTextView()
    }

    @IBAction func userInfoButton(_ sender: Any) {
        authStateManager?.getUser() { response, error in
            if let error = error {
                self.showMessage(error)
                return
            }

            if response != nil {
                var userInfoText = ""
                response?.forEach { userInfoText += ("\($0): \($1) \n") }
                self.showMessage(userInfoText)
            }
        }
    }

    @IBAction func introspectButton(_ sender: Any) {
        // Get current accessToken
        var accessToken = authStateManager?.accessToken
        if accessToken == nil {
            authStateManager?.renew { newAuthStateManager, error in
                if let error = error {
                    // Error
                    print("Error trying to Refresh AccessToken: \(error)")
                    return
                }
                self.authStateManager = newAuthStateManager
                accessToken = newAuthStateManager?.accessToken
                
                self.authStateManager?.introspect(token: accessToken, callback: { payload, error in
                    guard let isValid = payload?["active"] as? Bool else {
                        self.showMessage("Error: \(error?.localizedDescription ?? "Unknown")")
                        return
                    }
                    
                    self.showMessage("Is the AccessToken valid? - \(isValid)")
                })
            }
        } else {
            authStateManager?.introspect(token: accessToken, callback: { payload, error in
                guard let isValid = payload?["active"] as? Bool else {
                    self.showMessage("Error: \(error?.localizedDescription ?? "Unknown")")
                    return
                }

                self.showMessage("Is the AccessToken valid? - \(isValid)")
            })
        }
    }

    @IBAction func revokeButton(_ sender: Any) {
        // Get current accessToken
        guard let accessToken = authStateManager?.accessToken else {
            return
        }

        authStateManager?.revoke(accessToken) { _, error in
            if error != nil { self.showMessage("Error: \(error!)") }
            self.showMessage("AccessToken was revoked")
        }
    }

    func signInWithBrowser() {
        oktaAppAuth?.signInWithBrowser(from: self) { authStateManager, error in
            if let error = error {
                self.authStateManager = nil
                self.showMessage("Error: \(error.localizedDescription)")
                return
            }
            
            self.authStateManager = authStateManager
            self.buildTokenTextView()
        }
    }
    
    func signOut() {
        guard let authStateManager = authStateManager else { return }
        
        oktaAppAuth?.signOut(authStateManager: authStateManager, from: self, progressHandler: { currentOption in
            switch currentOption {
            case .revokeAccessToken, .revokeRefreshToken, .removeTokensFromStorage, .revokeTokensOptions:
                self.showMessage("Revoking tokens...")
            case .signOutFromOkta:
                self.showMessage("Signing out from Okta...")
            default:
                break
            }
        }, completionHandler: { success, _ in
            if success {
                self.authStateManager = nil
                self.buildTokenTextView()
            } else {
                self.showMessage("Error: failed to logout")
            }
        })
    }
    
    func showMessage(_ message: String) {
        tokenView.text = message
    }
    
    func showMessage(_ error: Error) {
        if let oidcError = error as? OktaOidcError {
            tokenView.text = oidcError.displayMessage
        } else {
            tokenView.text = error.localizedDescription
        }
    }

    func buildTokenTextView() {
        guard let currentManager = authStateManager else {
            tokenView.text = ""
            return
        }

        var tokenString = ""
        if let accessToken = currentManager.accessToken {
            tokenString += ("\nAccess Token: \(accessToken)\n")
        }

        if let idToken = currentManager.idToken {
            tokenString += "\nID Token: \(idToken)\n"
        }

        if let refreshToken = currentManager.refreshToken {
            tokenString += "\nRefresh Token: \(refreshToken)\n"
        }

        self.showMessage(tokenString)
    }
}

extension ViewController: OktaNetworkRequestCustomizationDelegate {
    func customizableURLRequest(_ request: URLRequest?) -> URLRequest? {
        if let request = request {
            print("request: \(request)")
        }
        return request
    }
   
    func didReceive(_ response: URLResponse?) {
        if let response = response {
            print("response: \(response)")
        }
    }
}

extension ViewController: OKTTokenValidator {
    func isIssued(atDateValid issuedAt: Date?, token: OKTTokenType) -> Bool {
        guard let issuedAt = issuedAt else {
            return false
        }
        
        let now = Date()
        
        return fabs(now.timeIntervalSince(issuedAt)) <= 200
    }
    
    func isDateExpired(_ expiry: Date?, token tokenType: OKTTokenType) -> Bool {
        guard let expiry = expiry else {
            return false
        }
        
        let now = Date()

        return now >= expiry
    }
}

extension OktaOidcError {
    var displayMessage: String {
        switch self {
        case let .api(message, _):
            switch (self as NSError).code {
            case NSURLErrorNotConnectedToInternet,
                NSURLErrorNetworkConnectionLost,
                NSURLErrorCannotLoadFromNetwork,
                NSURLErrorCancelled:
                return "No Internet Connection"
            case NSURLErrorTimedOut:
                return "Connection timed out"
            default:
                break
            }
            
            return "API Error occurred: \(message)"
        case let .authorization(error, _):
            return "Authorization error: \(error)"
        case let .unexpectedAuthCodeResponse(statusCode):
            return "Authorization failed due to incorrect status code: \(statusCode)"
        default:
            return localizedDescription
        }
    }
}
