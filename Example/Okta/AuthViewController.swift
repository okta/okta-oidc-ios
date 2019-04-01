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
    
    var oktaAppAuth: OktaAppAuth?
    var onAuthenticated: ((OktaAuthStateManager?) -> Void)?
    
    private var token: String? {
        return tokenTextView.text
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        oktaAppAuth?.authenticate(withSessionToken: token) { authStateManager, error in
            self.hideProgress()
            if let error = error {
                self.presentError(error)
                return
            }
            
            self.onAuthenticated?(authStateManager)
            self.dismiss(animated: true, completion: nil)
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
