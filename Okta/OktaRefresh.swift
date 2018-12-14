/*
 * Copyright (c) 2017, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */
import Hydra

internal struct Refresh {

    internal func refresh() -> Promise<String> {
        // Attempt to refresh the accessToken using the refreshToken
        return Promise<String>(in: .background, { resolve, reject, _ in
            guard let tokens = tokens else {
                return reject(OktaError.noTokens)
            }

            guard let _ = tokens.refreshToken else {
                return reject(OktaError.noRefreshToken)
            }

            tokens.authState.setNeedsTokenRefresh()
            tokens.authState.performAction(freshTokens: { accessToken, idToken, error in
                if error != nil {
                    return reject(OktaError.errorFetchingFreshTokens(error!.localizedDescription))
                }
                guard let token = accessToken else {
                    return reject(OktaError.errorFetchingFreshTokens("Access Token could not be refreshed."))
                }
                // Re-store the authState on token refreshing
                OktaAuth.tokens = tokens
                return resolve(token)
            })
        })
    }
}
