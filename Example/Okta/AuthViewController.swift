//
//  AuthViewController.swift
//  Okta_Example
//
//  Created by Anastasiia Iurok on 1/11/19.
//  Copyright © 2019 Okta. All rights reserved.
//

import UIKit
import OktaAuth

class AuthViewController : UIViewController {
    
    @IBOutlet var tokenTextView: UITextView!
    @IBOutlet var authenticateButton: UIButton!
    @IBOutlet var messageView: UITextView!
    
    @IBOutlet var progessOverlay: UIView!
    @IBOutlet var progessIndicator: UIActivityIndicatorView!
    
    private var isUITest: Bool {
        return ProcessInfo.processInfo.environment["UITEST"] == "1"
    }
    
    private var testConfig: OktaAuthConfig {
        return try! OktaAuthConfig(with: [
            "issuer": ProcessInfo.processInfo.environment["ISSUER"]!,
            "clientId": ProcessInfo.processInfo.environment["CLIENT_ID"]!,
            "redirectUri": ProcessInfo.processInfo.environment["REDIRECT_URI"]!,
            "logoutRedirectUri": ProcessInfo.processInfo.environment["LOGOUT_REDIRECT_URI"]!,
            "scopes": "openid profile offline_access"
        ])
    }
    
    private var token: String? {
        return tokenTextView.text
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        OktaAuth.configuration = isUITest ? testConfig : try! OktaAuthConfig.default()
        hideProgress()
        clearMessageView()
    }
    
    @IBAction func authenticate() {
        guard let token = token, !token.isEmpty else {
            self.showMessage("You MUST specify session token to authenticate!")
            return
        }
        
        clearMessageView()
        showProgress()
        OktaAuth.authenticate(withSessionToken: token) { tokens, error in
            self.hideProgress()
            if let error = error {
                self.presentError(error)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func presentError(_ error: Error) {
        self.showMessage("Error: \(error.localizedDescription)")
    }
    
    func showMessage(_ message: String) {
        messageView.text = message
    }
    
    func clearMessageView() {
        messageView.text = nil
    }
    
    func showProgress() {
        progessIndicator.startAnimating()
        progessOverlay.isHidden = false
    }
    
    func hideProgress() {
        progessIndicator.stopAnimating()
        progessOverlay.isHidden = true
    }
}
