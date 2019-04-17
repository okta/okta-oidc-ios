/*
 * Copyright (c) 2019, Okta, Inc. and/or its affiliates. All rights reserved.
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

class ViewController: UIViewController {

    @IBOutlet weak var tokenView: UITextView!
    @IBOutlet weak var signInButton: UIButton!
    
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
        oktaAppAuth = try? OktaOidc(configuration: isUITest ? testConfig : nil)
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
    
    @IBAction func signOutOfOktaButton(_ sender: Any) {
        self.signOutOfOkta()
    }

    @IBAction func clearTokens(_ sender: Any) {
        authStateManager?.clear()
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
    
    func signOutOfOkta() {
        guard let authStateManager = authStateManager else { return }

        oktaAppAuth?.signOutOfOkta(authStateManager, from: self) { error in
            if let error = error {
                self.updateUI(updateText: "Error: \(error)")
                return
            }
            
            self.authStateManager = nil
            self.buildTokenTextView()
        }
    }

    func updateUI(updateText: String) {
        DispatchQueue.main.async { self.tokenView.text = updateText }
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
