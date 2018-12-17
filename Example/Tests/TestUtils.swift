//
//  TestUtils.swift
//  Okta_Example
//
//  Created by Jordan Melberg on 3/13/18.
//  Copyright © 2018 Okta. All rights reserved.
//

import AppAuth
@testable import OktaAuth
import Hydra

struct TestUtils {
    static let mockIssuer = "https://demo-org.oktapreview.com/oauth2/default"
    static let mockClientId = "0oae1enia6od2nlz00h7"
    static let mockClientSecret = "clientSecret"
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

    static let tokenManager = TestUtils.setupMockTokenManager(issuer: mockIssuer)
    static let tokenManagerNoValidation = TestUtils.setupMockTokenManager(issuer: mockIssuer)
    static let tokenManagerNoValidationWithExpiration = TestUtils.setupMockTokenManager(issuer: mockIssuer, expiresIn: 5)


    static func setupMockTokenManager(issuer: String, expiresIn: TimeInterval = 300) -> Promise<OktaTokenManager> {
        // Creates a mock Okta Token Manager object
        let fooURL = URL(string: issuer)!
        let mockServiceConfig = OIDServiceConfiguration(authorizationEndpoint: fooURL, tokenEndpoint: fooURL)
        let mockTokenRequest = OIDTokenRequest(
                   configuration: mockServiceConfig,
                       grantType: OIDGrantTypeRefreshToken,
               authorizationCode: nil,
                     redirectURL: fooURL,
                        clientID: "nil",
                    clientSecret: nil,
                           scope: nil,
                    refreshToken: nil,
                    codeVerifier: nil,
            additionalParameters: nil
        )

        let mockAuthRequest = OIDAuthorizationRequest(
                   configuration: mockServiceConfig,
                        clientId: mockClientId,
                    clientSecret: nil,
                          scopes: ["openid", "email"],
                     redirectURL: fooURL,
                    responseType: OIDResponseTypeCode,
            additionalParameters: nil
        )

        let mockAuthResponse = OIDAuthorizationResponse(
               request: mockAuthRequest,
            parameters: ["code": "mockAuthCode" as NSCopying & NSObjectProtocol]
        )

        let mockTokenResponse = OIDTokenResponse(
            request: mockTokenRequest,
            parameters: [
                "access_token": mockAccessToken as NSCopying & NSObjectProtocol,
                "expires_in": expiresIn as NSCopying & NSObjectProtocol,
                "token_type": "Bearer" as NSCopying & NSObjectProtocol,
                "id_token": mockIdToken as NSCopying & NSObjectProtocol,
                "refresh_token": mockRefreshToken as NSCopying & NSObjectProtocol,
                "scope": mockScopes as NSCopying & NSObjectProtocol
            ]
        )

        let tempAuthState = OIDAuthState(authorizationResponse: mockAuthResponse, tokenResponse: mockTokenResponse)

        return Promise<OktaTokenManager>(in: .background, { resolve, reject, _ in
            do {
                let tm = try OktaTokenManager(
                    authState: tempAuthState,
                    config: [
                        "issuer": mockIssuer,
                        "clientId": mockClientId,
                        "clientSecret": mockClientSecret,
                        "redirectUri": mockRedirectUri
                    ]
                )
                return resolve(tm)
            } catch let error {
                return reject(error)
            }
        })
    }

    static func getPreviousState() -> OktaTokenManager? {
        // Return the previous archived state
        guard let encodedAuthState: Data = try? OktaKeychain.get(key: "OktaAuthStateTokenManager") else {
            return nil
        }
        guard let previousState = NSKeyedUnarchiver
            .unarchiveObject(with: encodedAuthState) as? OktaTokenManager else {
                return nil
        }
        return previousState
    }
}
