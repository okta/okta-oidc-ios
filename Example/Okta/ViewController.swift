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

    override func viewDidLoad() { super.viewDidLoad() }

    @IBAction func loginButton(_ sender: Any) {
        if tokens == nil { self.loginCodeFlow() }
    }

    @IBAction func refreshTokens(_ sender: Any) {
        OktaAuth.refresh()
        self.buildTokenTextView()
    }

    @IBAction func clearTokens(_ sender: Any) {
        OktaAuth.clear()
        self.buildTokenTextView()
    }

    @IBAction func userInfoButton(_ sender: Any) {
        // Get current accessToken
        let accessToken = tokens?.accessToken
        if accessToken == nil { return }

        OktaAuth
            .userinfo { response, error in
                if error != nil { print("Error: \(error!)") }
                if response != nil {
                    var userInfoText = ""
                    response?.forEach { userInfoText += ("\($0): \($1)\n\n") }
                    self.updateUI(updateText: userInfoText)
                }
        }
    }

    @IBAction func introspectButton(_ sender: Any) {
        // Get current accessToken
        let accessToken = tokens?.accessToken
        if accessToken == nil { return }

        OktaAuth
            .introspect()
            .validate(accessToken!) { response, error in
                if error != nil { self.updateUI(updateText: "Error: \(error!)") }
                if let isActive = response { self.updateUI(updateText: "Is the AccessToken valid? \(isActive)") }
        }
    }

    @IBAction func revokeButton(_ sender: Any) {
        // Get current accessToken
        let accessToken = tokens?.accessToken
        if accessToken == nil { return }

        OktaAuth.revoke(accessToken!) { response, error in
            if error != nil { self.updateUI(updateText: "Error: \(error!)") }
            if response != nil { self.updateUI(updateText: "AccessToken was revoked") }
        }
    }

    func loginCodeFlow() {
        OktaAuth
            .login()
            .start(self) { response, error in
                if error != nil { print(error!) }
                if let authResponse = response {
                    // Store tokens in keychain
                    tokens?.set(value: authResponse.accessToken!, forKey: "accessToken")
                    tokens?.set(value: authResponse.idToken!, forKey: "idToken")
                    self.buildTokenTextView()
                }
        }
    }

    func updateUI(updateText: String) {
        DispatchQueue.main.async { self.tokenView.text = updateText }
    }

    func buildTokenTextView() {
        if tokens == nil {
            tokenView.text = ""
            return
        }

        var tokenString = ""

        if let accessToken = tokens?.accessToken {
            tokenString += ("\nAccess Token: \(accessToken)\n")
        }

        if let idToken = tokens?.idToken {
            tokenString += "\n IdToken: \(idToken)\n"
        }

        if let refreshToken = tokens?.refreshToken {
            tokenString += "\nRefresh Token: \(refreshToken)\n"
        }

        self.updateUI(updateText: tokenString)
    }
}
