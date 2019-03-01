//
//  ViewController.swift
//  Okta
//
//  Created by jmelberg on 06/17/2017.
//  Copyright (c) 2017 jmelberg. All rights reserved.
//

import UIKit
import OktaAuth

class ViewController: UIViewController {

    @IBOutlet weak var tokenView: UITextView!
    @IBOutlet weak var signInButton: UIButton!
    
    private var isUITest: Bool {
        return ProcessInfo.processInfo.environment["UITEST"] == "1"
    }
    
    private var testConfig: OktaAuthConfig? {
        return try? OktaAuthConfig(with:[
            "issuer": ProcessInfo.processInfo.environment["ISSUER"]!,
            "clientId": ProcessInfo.processInfo.environment["CLIENT_ID"]!,
            "redirectUri": ProcessInfo.processInfo.environment["REDIRECT_URI"]!,
            "logoutRedirectUri": ProcessInfo.processInfo.environment["LOGOUT_REDIRECT_URI"]!,
            "scopes": "openid profile offline_access"
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        OktaAuth.configuration = self.isUITest ? testConfig : try? OktaAuthConfig.default()
        if OktaAuth.isAuthenticated {
            // If there is a valid accessToken
            // build the token view.
            self.buildTokenTextView()
        }
    }

    @IBAction func signInButton(_ sender: Any) {
        self.signInWithBrowser()
    }
    
    @IBAction func signOutOfOktaButton(_ sender: Any) {
        self.signOutOfOkta()
    }

    @IBAction func clearTokens(_ sender: Any) {
        OktaAuth.clear()
        self.buildTokenTextView()
    }

    @IBAction func userInfoButton(_ sender: Any) {
        OktaAuth.getUser { response, error in
            if let error = error { self.updateUI(updateText: "Error: \(error)") }
            if response != nil {
                var userInfoText = ""
                response?.forEach { userInfoText += ("\($0): \($1) \n") }
                self.updateUI(updateText: userInfoText)
            }
        }
    }

    @IBAction func introspectButton(_ sender: Any) {
        // Get current accessToken
        guard let accessToken = tokenManager?.accessToken else { return }

        tokenManager?.introspect(token: accessToken, callback: { payload, error in
            guard let isValid = payload?["active"] as? Bool else {
                self.updateUI(updateText: "Error: \(error?.localizedDescription ?? "Unknown")")
                return
            }
            
            self.updateUI(updateText: "Is the AccessToken valid? - \(isValid)")
        })
    }

    @IBAction func revokeButton(_ sender: Any) {
        // Get current accessToken
        guard let accessToken = tokenManager?.accessToken else { return }

        tokenManager?.revoke(accessToken) { response, error in
            if error != nil { self.updateUI(updateText: "Error: \(error!)") }
            if response != nil { self.updateUI(updateText: "AccessToken was revoked") }
        }
    }

    func signInWithBrowser() {
        OktaAuth.signInWithBrowser(from: self) { tokens, error in
            if let error = error {
                self.updateUI(updateText: "Error: \(error)")
                return
            }
            
            self.buildTokenTextView()
        }
    }
    
    func signOutOfOkta() {
        OktaAuth.signOutOfOkta(from: self) { error in
            if let error = error {
                self.updateUI(updateText: "Error: \(error)")
                return
            }
            
            self.buildTokenTextView()
        }
    }

    func updateUI(updateText: String) {
        DispatchQueue.main.async { self.tokenView.text = updateText }
    }

    func buildTokenTextView() {
        guard let currentTokens = tokenManager else {
            tokenView.text = ""
            return
        }

        var tokenString = ""
        if let accessToken = currentTokens.accessToken {
            tokenString += ("\nAccess Token: \(accessToken)\n")
        }

        if let idToken = currentTokens.idToken {
            tokenString += "\nID Token: \(idToken)\n"
        }

        if let refreshToken = currentTokens.refreshToken {
            tokenString += "\nRefresh Token: \(refreshToken)\n"
        }

        self.updateUI(updateText: tokenString)
    }
}
