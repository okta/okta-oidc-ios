//
//  TestUtils.swift
//  Okta_Example
//
//  Created by Jordan Melberg on 3/13/18.
//  Copyright © 2018 Okta. All rights reserved.
//

import AppAuth
import OktaAuth
import Vinculum

struct TestUtils {
    static let tokenManager = TestUtils.setupMockTokenManager(issuer: "https://demo-org.oktapreview.com/oauth2/default")

    static func setupMockTokenManager(issuer: String) -> OktaTokenManager {
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
        let mockTokenResponse = OIDTokenResponse(request: mockTokenRequest, parameters: [:])
        let tempAuthState = OIDAuthState(authorizationResponse: nil, tokenResponse: mockTokenResponse, registrationResponse: nil)

        return OktaTokenManager(authState: tempAuthState, config: [:])
    }

    static func getPreviousState() -> OktaTokenManager? {
        // Return the previous archived state
        guard let encodedAuthStateItem = try? Vinculum.get("OktaAuthStateTokenManager"),
            let encodedAuthState = encodedAuthStateItem else {
                return nil
        }
        guard let previousState = NSKeyedUnarchiver
            .unarchiveObject(with: encodedAuthState.value) as? OktaTokenManager else {
                return nil
        }

        return previousState
    }
}
