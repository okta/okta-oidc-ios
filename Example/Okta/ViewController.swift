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
    @IBOutlet weak var redirectLoginButton: UIButton!
    
    private var isUITest: Bool {
        return ProcessInfo.processInfo.environment["UITEST"] == "1"
    }
    
    private var testConfig: [String: String] {
        return [
            "issuer": ProcessInfo.processInfo.environment["ISSUER"]!,
            "clientId": ProcessInfo.processInfo.environment["CLIENT_ID"]!,
            "redirectUri": ProcessInfo.processInfo.environment["REDIRECT_URI"]!,
            "logoutRedirectUri": ProcessInfo.processInfo.environment["LOGOUT_REDIRECT_URI"]!,
            "scopes": "openid profile offline_access"
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if OktaAuth.isAuthenticated() {
            // If there is a valid accessToken
            // build the token view.
            self.buildTokenTextView()
        }
    }

    @IBAction func loginButton(_ sender: Any) {
        self.loginCodeFlow()
    }
    
    @IBAction func signOutOfOktaButton(_ sender: Any) {
        self.signOutOfOkta()
    }
    
    @IBAction func clearAndRevokeTokensButton(_ sender: Any) {
        OktaAuth.clearTokens()
        .then { self.buildTokenTextView() }
        .catch { error in self.updateUI(updateText: "Error: \(error)") }
    }

    @IBAction func clearTokens(_ sender: Any) {
        OktaAuth.clearTokens(revokeTokens: false)
        .then{ self.buildTokenTextView() }
        .catch { error in self.updateUI(updateText: "Error: \(error)") }
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
        guard let accessToken = tokens?.accessToken else { return }

        OktaAuth.introspect().validate(accessToken)
        .then { response in self.updateUI(updateText: "Is the AccessToken valid? \(response)") }
        .catch { error in self.updateUI(updateText: "Error: \(error)") }
    }

    @IBAction func revokeButton(_ sender: Any) {
        // Get current accessToken
        guard let accessToken = tokens?.accessToken else { return }

        OktaAuth.revoke(accessToken) { response, error in
            if error != nil { self.updateUI(updateText: "Error: \(error!)") }
            if response != nil { self.updateUI(updateText: "AccessToken was revoked") }
        }
    }

    func loginCodeFlow() {
        if self.isUITest {
            OktaAuth.login().start(withDictConfig: testConfig, view: self)
            .then { _ in self.buildTokenTextView() }
            .catch { error in self.updateUI(updateText: "Error: \(error)") }
        } else {
            OktaAuth.login().start(self)
            .then { _ in self.buildTokenTextView() }
            .catch { error in self.updateUI(updateText: "Error: \(error)") }
        }
    }
    
    func signOutOfOkta() {
        if self.isUITest {
            OktaAuth.signOutOfOkta().start(withDictConfig: testConfig, view: self)
            .then { _ in self.buildTokenTextView() }
            .catch { error in self.updateUI(updateText: "Error: \(error)") }
        } else {
            OktaAuth.signOutOfOkta().start(self)
            .then { self.buildTokenTextView() }
            .catch { error in self.updateUI(updateText: "Error: \(error)") }
        }
    }

    func updateUI(updateText: String) {
        DispatchQueue.main.async { self.tokenView.text = updateText }
    }

    func buildTokenTextView() {
        guard let currentTokens = tokens else {
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
