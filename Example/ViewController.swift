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

import UIKit
import OktaOidc

final class ViewController: UIViewController {

    @IBOutlet private weak var tokenView: UITextView!
    @IBOutlet private weak var signInButton: UIButton!
    
    private var oktaAppAuth: OktaOidc?
    private var authStateManager: OktaOidcStateManager? {
        didSet {
            oldValue?.clear()
            authStateManager?.writeToSecureStorage()
        }
    }
    
    private var isUITest: Bool {
        return ProcessInfo.processInfo.environment["UITEST"] == "1"
    }
    
    private var testConfig: OktaOidcConfig? {
        return try? OktaOidcConfig(with:[
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
        oktaAppAuth = try? OktaOidc(configuration: isUITest ? testConfig : configuration)
        AppDelegate.shared.oktaOidc = oktaAppAuth
        
        if let config = oktaAppAuth?.configuration {
            authStateManager = OktaOidcStateManager.readFromSecureStorage(for: config)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let _ = oktaAppAuth else {
            self.updateUI(updateText: "SDK is not configured!")
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
        authStateManager?.clear()
        try? authStateManager?.removeFromSecureStorage()
        authStateManager = nil
        
        self.buildTokenTextView()
    }

    @IBAction func userInfoButton(_ sender: Any) {
        authStateManager?.getUser() { response, error in
            if let error = error {
                self.updateUI(updateText: "Error: \(error)")
                return
            }

            if response != nil {
                var userInfoText = ""
                response?.forEach { userInfoText += ("\($0): \($1) \n") }
                self.updateUI(updateText: userInfoText)
            }
        }
    }

    @IBAction func introspectButton(_ sender: Any) {
        // Get current accessToken
        guard let accessToken = authStateManager?.accessToken else { return }

        authStateManager?.introspect(token: accessToken, callback: { payload, error in
            guard let isValid = payload?["active"] as? Bool else {
                self.updateUI(updateText: "Error: \(error?.localizedDescription ?? "Unknown")")
                return
            }
            
            self.updateUI(updateText: "Is the AccessToken valid? - \(isValid)")
        })
    }

    @IBAction func revokeButton(_ sender: Any) {
        // Get current accessToken
        guard let accessToken = authStateManager?.accessToken else { return }

        authStateManager?.revoke(accessToken) { response, error in
            if error != nil { self.updateUI(updateText: "Error: \(error!)") }
            self.updateUI(updateText: "AccessToken was revoked")
        }
    }

    func signInWithBrowser() {
        oktaAppAuth?.signInWithBrowser(from: self) { authStateManager, error in
            if let error = error {
                self.authStateManager = nil
                self.updateUI(updateText: "Error: \(error)")
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
                self.updateUI(updateText: "Revoking tokens...")
            case .signOutFromOkta:
                self.updateUI(updateText: "Signing out from Okta...")
            case .allOptions:
                break
            default:
                break
            }
        }, completionHandler: { success, failedOptions in
            if success {
                self.authStateManager = nil
                self.buildTokenTextView()
            } else {
                self.updateUI(updateText: "Error: failed to logout")
            }
        })
    }

    func updateUI(updateText: String) {
        tokenView.text = updateText
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

        self.updateUI(updateText: tokenString)
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
