/*
 * Copyright (c) 2017-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import OktaOidc
import UIKit

final class AuthViewController: UIViewController {
    
    @IBOutlet private weak var tokenTextView: UITextView!
    @IBOutlet private weak var authenticateButton: UIButton!
    @IBOutlet private weak var messageView: UITextView!
    
    @IBOutlet private weak var progessOverlay: UIView!
    @IBOutlet private weak var progessIndicator: UIActivityIndicatorView!
    
    var oktaAppAuth: OktaOidc?
    var onAuthenticated: ((OktaOidcStateManager?) -> Void)?
    
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
                self.showMessage(error)
                return
            }
            
            self.onAuthenticated?(authStateManager)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func showMessage(_ error: Error) {
        if let oidcError = error as? OktaOidcError {
            messageView.text = oidcError.displayMessage
        } else {
            messageView.text = error.localizedDescription
        }
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
