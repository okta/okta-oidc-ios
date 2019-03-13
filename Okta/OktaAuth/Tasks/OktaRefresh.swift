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

class RefreshTask: OktaAuthTask<String> {

    override func run(callback: @escaping (String?, OktaError?) -> Void) {
        guard let tokenManager = tokenManager else {
            callback(nil, OktaError.noTokens)
            return
        }

        guard let _ = tokenManager.refreshToken else {
            callback(nil, OktaError.noRefreshToken)
            return
        }
        
         tokenManager.authState.setNeedsTokenRefresh()
        
         tokenManager.authState.performAction(freshTokens: { accessToken, idToken, error in
            if error != nil {
                callback(nil, OktaError.errorFetchingFreshTokens(error!.localizedDescription))
                return
            }
            guard let token = accessToken else {
                callback(nil, OktaError.errorFetchingFreshTokens("Access Token could not be refreshed."))
                return
            }

            // Re-store the authState on token refreshing
            OktaAuth.tokenManager = tokenManager
            
            callback(token, nil)
        })
    }
}
