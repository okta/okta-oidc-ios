/*
 * Copyright (c) 2019-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

// swiftlint:disable force_try
// swiftlint:disable force_cast
// swiftlint:disable force_unwrapping

@testable import OktaOidc

struct TestUtils {
    static let mockIssuer = "https://demo-org.oktapreview.com/oauth2/default"
    static let mockClientId = "0oae1enia6od2nlz00h7"
    static let mockRedirectUri = "com.okta.example:/callback"
    static let mockScopes = "openid email"

    static let mockAccessToken = "abc.123.xyz"
    static let mockIdToken = "eyJraWQiOiIwWG9xWm1abTVuQlF0UnhUd3E1VDI5czBUenF0RGowenNyOGxGSHA5OHZnIiwiYWxnIjoiUlMyNTYifQ." +
        "eyJzdWIiOiIwMHVlMWdpMHB0WnBhNjdwVTBoNyIsIm5hbWUiOiJKb3JkYW4gTWVsYmVyZyIsInZlciI6MSwiaXNzIjoiaHR0cHM6Ly9kZW1vLW9yZy" +
        "5va3RhcHJldmlldy5jb20vb2F1dGgyL2RlZmF1bHQiLCJhdWQiOiIwb2FlMWVuaWE2b2Qybmx6MDBoNyIsImlhdCI6MTUyMTIzMDMzNiwiZXhwIjox" +
        "NTIxMjMzOTM2LCJqdGkiOiJJRC5Fc0g5MndqVU1fNTJOdHg1Mlc0QkFpNGVlRUlJak5WbFZYaVZxbkR5S2U4IiwiYW1yIjpbInB3ZCJdLCJpZHAiOi" +
        "IwMG9lMWdpMG5mU3FBY0VaMjBoNyIsInByZWZlcnJlZF91c2VybmFtZSI6ImpvcmRhbi5tZWxiZXJnQG9rdGEuY29tIiwiYXV0aF90aW1lIjoxNTIx" +
        "MjMwMzM1LCJhdF9oYXNoIjoiUmNRM2dHeXQ3bHJIckFwenF4RkxmQSJ9.GTrgb19Rb_hJhcKj1NvvMfhkX9_bbn5RNCefH285TEJL0lsmytC60GUiY-" +
        "MQfI0DkjvBC7Yd2NS4hQyX3YlUn5vWcL6B_cQe-nSR3RD8pvnfmKh28mGrqtn0qfLxq9LmPskKZuXgjBY_hiFpRW-XzGWOgfYp-6t6oDN4LP92bnNNW" +
        "qNelEI21kePdJQ3fItn3lwhBAFzJ3X35LOJr4-4XAqF0K-dOcpJ_EVyVMUtuQ4s3CD5xfrhYeRbz8d8As7Np7CCqTpWgS1L4AVMvMwdu6QaCo2bMYqH" +
        "pu1WrZzuBHoQXuDkuYH6xKbKU2bopZGnA8PwrsIbr6PmmTaeH5ww0Q"
    static let mockRefreshToken = "mockRefreshToken"

    static var authStateManager = { return TestUtils.setupMockAuthStateManager(issuer: mockIssuer, clientId: mockClientId) }
    static var authStateManagerWithExpiration = { return TestUtils.setupMockAuthStateManager(issuer: mockIssuer, clientId: mockClientId, expiresIn: 5) }
    
    static func makeMockServiceConfig(issuer: URL) -> OKTServiceConfiguration {
        OKTServiceConfiguration(authorizationEndpoint: issuer, tokenEndpoint: issuer, issuer: issuer)
    }
    
    static func setupMockAuthState(issuer: String,
                                   clientId: String,
                                   expiresIn: TimeInterval = 300,
                                   refreshToken: String = Self.mockRefreshToken,
                                   skipTokenResponse: Bool = false) -> OKTAuthState {
        // Creates a mock Okta Auth State Manager object
        let fooURL = URL(string: issuer)!
        let mockServiceConfig = makeMockServiceConfig(issuer: fooURL)
        
        let mockTokenRequest = OKTTokenRequest(
                   configuration: mockServiceConfig,
                       grantType: OKTGrantTypeRefreshToken,
               authorizationCode: nil,
                     redirectURL: fooURL,
                        clientID: "nil",
                    clientSecret: nil,
                           scope: nil,
                    refreshToken: nil,
                    codeVerifier: nil,
            additionalParameters: nil
        )

        let mockAuthRequest = OKTAuthorizationRequest(
                   configuration: mockServiceConfig,
                        clientId: clientId,
                    clientSecret: nil,
                          scopes: ["openid", "email"],
                     redirectURL: fooURL,
                    responseType: OKTResponseTypeCode,
            additionalParameters: nil
        )

        let mockAuthResponse = OKTAuthorizationResponse(
               request: mockAuthRequest,
            parameters: ["code": "mockAuthCode" as NSCopying & NSObjectProtocol]
        )

        if skipTokenResponse {
            return OKTAuthState(authorizationResponse: mockAuthResponse)
        } else {
            let mockTokenResponse = OKTTokenResponse(
                request: mockTokenRequest,
                parameters: [
                    "access_token": mockAccessToken as NSCopying & NSObjectProtocol,
                    "expires_in": expiresIn as NSCopying & NSObjectProtocol,
                    "token_type": "Bearer" as NSCopying & NSObjectProtocol,
                    "id_token": mockIdToken as NSCopying & NSObjectProtocol,
                    "refresh_token": refreshToken as NSCopying & NSObjectProtocol,
                    "scope": mockScopes as NSCopying & NSObjectProtocol
                ]
            )

            return OKTAuthState(authorizationResponse: mockAuthResponse, tokenResponse: mockTokenResponse)
        }
    }

    static func setupMockAuthStateManager(issuer: String, clientId: String, expiresIn: TimeInterval = 300) -> OktaOidcStateManager {
        let tempAuthState = setupMockAuthState(issuer: issuer, clientId: clientId, expiresIn: expiresIn)
        return OktaOidcStateManager(authState: tempAuthState)
    }
}
