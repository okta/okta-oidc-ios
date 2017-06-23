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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        OktaAuth
            .login()
            .start(self) {
                response, error in
                
                if error != nil { print(error!) }
                if let authResponse = response {
                    var tokenString = ""
                    if let accessToken = authResponse.accessToken {
                        tokenString = tokenString + ("\nAccess Token: \(accessToken)\n")
                    } else {
                        tokenString = tokenString + "\nDid not receive accessToken\n"
                    }
                    
                    if let idToken = authResponse.idToken {
                        tokenString = tokenString + "\nidToken Token: \(idToken)\n"
                    } else {
                        tokenString = tokenString + "\nDid not receive idToken\n"
                    }
                    
                    if let refreshToken = authResponse.refreshToken {
                        tokenString = tokenString + "\nrefresh Token: \(refreshToken)\n"
                    } else {
                        tokenString = tokenString + "\nDid not receive refreshToken\n"
                    }
                    
                    self.tokenView.text = tokenString
                }
                
            }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    func callRevoke(token: String) {
        OktaAuth.revoke(token) {
            response, error in
            
            if error != nil { print("Error: \(error!)") }
            if let _ = response { print("Token was revoked") }
        }
    }
    
    func callIntrospect(token: String) {
        OktaAuth
            .introspect()
            .validate(token) {
                response, error in
                
                if error != nil { print("Error: \(error!)") }
                if let isActive = response { print("Is token valid? \(isActive)") }
            }
    }
    
    func callUserInfo() {
        OktaAuth.userinfo() {
            response, error in
            
            if error != nil { print("Error: \(error!)") }
            
            if response != nil {
                response?.forEach { print("\($0.0): \($0.1)") }
            }
        }
    }
}
