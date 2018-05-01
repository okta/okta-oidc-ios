//
//  LoginFormViewController.swift
//  Okta_Example
//
//  Created by Jordan Melberg on 3/20/18.
//  Copyright © 2018 Okta. All rights reserved.
//

import UIKit
import OktaAuth

class LoginFormViewController: UIViewController {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var errorField: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBAction func login(_ sender: Any) {
        if usernameField.text == "" || passwordField.text == "" {
            errorField.text = "Missing credentials"
            return
        }
        guard let username = usernameField.text, let password = passwordField.text else {
            errorField.text = "Error capturing credentials"
            return
        }
        
        if Utils.getPlistConfiguration(forResourceName: "Okta-PasswordFlow") == nil {
            errorField.text = "Please update the Okta-PasswordFlow.plist file to use this flow."
            return
        }
        activityIndicator.startAnimating()

        OktaAuth.login(username, password: password).start(withPListConfig: "Okta-PasswordFlow", view: self)
        .then { tokenManager in
            self.dismissView()
        }
        .catch { error in
            self.activityIndicator.stopAnimating()
            self.errorField.text = error.localizedDescription
            return
        }
    }
    @IBAction func cancel(_ sender: Any) {
        self.dismissView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func dismissView() {
        activityIndicator.stopAnimating()
        navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }

}
