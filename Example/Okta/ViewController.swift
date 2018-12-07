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
    
    @IBAction func logoutButton(_ sender: Any) {
        self.logoutCodeFlow()
    }

    @IBAction func clearTokens(_ sender: Any) {
        OktaAuth.clear()
        self.buildTokenTextView()
    }

    @IBAction func userInfoButton(_ sender: Any) {
        OktaAuth.getUser { response, error in
            if error != nil { print("Error: \(error!)") }
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
        if ProcessInfo.processInfo.environment["UITEST"] == "1" {
            let config = ["issuer": ProcessInfo.processInfo.environment["ISSUER"]!,
                          "clientId": ProcessInfo.processInfo.environment["CLIENT_ID"]!,
                          "redirectUri": ProcessInfo.processInfo.environment["REDIRECT_URI"]!,
                          "scopes": "openid profile offline_access"]
            OktaAuth.login().start(withDictConfig: config, view: self).then { _ in self.buildTokenTextView() }.catch { error in print(error) }
        } else {
            OktaAuth.login().start(self).then { _ in self.buildTokenTextView() }.catch { error in print(error) }
        }
    }
    
    func logoutCodeFlow() {
        OktaAuth.logout().start(self)
        .then { self.buildTokenTextView() }
        .catch { error in print(error) }
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
