/*
 * Copyright (c) 2018-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import Foundation
import OktaAppAuth
import SafariServices

class OktaExternalUserAgentIOS : NSObject, OIDExternalUserAgent {
    
    private let presentingViewController: UIViewController
    fileprivate var safariViewController: SFSafariViewController?
    
    fileprivate var session: OIDExternalUserAgentSession?
    
    fileprivate var externalUserAgentFlowInProgress: Bool = false
    
    init(presenting presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
    }

    func present(_ request: OIDExternalUserAgentRequest, session: OIDExternalUserAgentSession) -> Bool {
        guard !externalUserAgentFlowInProgress else {
            return false
        }
        
        guard let requestURL = request.externalUserAgentRequestURL() else {
            return false
        }
        self.session = session
        externalUserAgentFlowInProgress = true
        var isBrowserLaunched = false
        
        if #available(iOS 9.0, *) {
            safariViewController = SFSafariViewController(url: requestURL, entersReaderIfAvailable: false)
            safariViewController?.delegate = self
            presentingViewController.present(safariViewController!, animated: true)
            isBrowserLaunched = true
        }
        else {
            isBrowserLaunched = UIApplication.shared.openURL(requestURL)
        }
        
        if !isBrowserLaunched {
            cleanup()
            let error = OIDErrorUtilities.error(
                with: .safariOpenError,
                underlyingError: nil,
                description: "Unable to open Safari.")
            session.failExternalUserAgentFlowWithError(error)
        }
        
        return isBrowserLaunched
    }
    
    func dismiss(animated: Bool, completion: @escaping () -> Void) {
        guard externalUserAgentFlowInProgress else {
            return
        }
        
        if #available(iOS 9.0, *) {
            if let safariVC = safariViewController {
                safariVC.dismiss(animated: true, completion: completion)
            } else {
                completion()
            }
        } else {
            completion()
        }
        
        cleanup()
    }
    
    fileprivate func cleanup() {
        externalUserAgentFlowInProgress = false
        safariViewController = nil
        session = nil
    }
}

extension OktaExternalUserAgentIOS : SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        guard controller == safariViewController else {
            // Ignore this call if the safari view controller do not match.
            return
        }

        guard externalUserAgentFlowInProgress else {
            // Ignore this call if there is no authorization flow in progress.
            return
        }

        let currentSession = session
        cleanup()

        let error = OIDErrorUtilities.error(
            with: .userCanceledAuthorizationFlow,
            underlyingError: nil,
            description: "No external user agent flow in progress.")
        currentSession?.failExternalUserAgentFlowWithError(error)
    }
}
