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
            guard let refreshToken = tokens?.refreshToken else {
                return reject(OktaError.NoRefreshToken)
            }

            if tokens?.authState.lastAuthorizationResponse == nil {
                // Use the cached refreshToken to mint new tokens
                guard let config = OktaAuth.configuration as? [String: String] else {
                    return reject(OktaError.ParseFailure)
                }

                OktaAuthorization().refreshTokensManually(config, refreshToken: refreshToken)
                .then { response in
                    guard let accessToken = response.accessToken else {
                        return reject(OktaError.ErrorFetchingFreshTokens("Access Token could not be refreshed."))
                    }
                    return resolve(accessToken)
                }
                .catch { error in return reject(error) }
                return
            }

            tokens?.authState.setNeedsTokenRefresh()
            tokens?.authState.performAction(freshTokens: { accessToken, idToken, error in
                if error != nil {
                    return reject(OktaError.ErrorFetchingFreshTokens(error!.localizedDescription))
                }
                guard let token = accessToken else {
                    return reject(OktaError.ErrorFetchingFreshTokens("Access Token could not be refreshed."))
                }
                return resolve(token)
            })
        })
    }
}
