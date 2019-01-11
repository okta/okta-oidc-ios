//
//  ResumeSessionViewController.swift
//  Okta_Example
//
//  Created by Anastasiia Iurok on 1/11/19.
//  Copyright © 2019 Okta. All rights reserved.
//

import UIKit
import OktaAuth

class ResumeSessionViewController : UIViewController {
    
    @IBOutlet var tokenTextView: UITextView!
    @IBOutlet var resumeButton: UIButton!
    @IBOutlet var messageView: UITextView!
    
    @IBOutlet var progessOverlay: UIView!
    @IBOutlet var progessIndicator: UIActivityIndicatorView!
    
    private var token: String? {
        return tokenTextView.text
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        hideProgress()
        clearMessageView()
    }
    
    @IBAction func resume() {
        guard let token = token, !token.isEmpty else {
            self.showMessage("You MUST specify token to resume session!")
            return
        }
        
        clearMessageView()
        showProgress()
        
        OktaAuth.resumeSession(token).start()
        .then { tokenManager in
            self.hideProgress()
            self.dismiss(animated: true, completion: nil)
        }
        .catch { error in
            self.hideProgress()
            self.presentError(error)
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
