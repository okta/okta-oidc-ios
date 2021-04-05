/*
 * Copyright (c) 2020-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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

import Foundation

#if SWIFT_PACKAGE
@testable import OktaOidc_AppAuth
#else
@testable import OktaOidc
#endif

final class OKTTokensAuthMock: OKTAuthState {
    
    private var shouldFailRefresh = false
    
    static func makeDefault(expiresIn: TimeInterval = 10, expiredIDToken: Bool = false, shouldFailRefresh: Bool = false) -> OKTAuthState {
        let issuer = URL(string: TestUtils.mockIssuer)!
        let mockConfig = TestUtils.makeMockServiceConfig(issuer: issuer)
        
        let mockAuthRequest = OKTAuthorizationRequest(
            configuration: mockConfig,
            clientId: TestUtils.mockClientId,
            clientSecret: nil,
            scopes: ["openid", "email"],
            redirectURL: issuer,
            responseType: OKTResponseTypeCode,
            additionalParameters: nil
        )
        
        let mockAuthResponse = OKTAuthorizationResponse(
            request: mockAuthRequest,
            parameters: ["code": "mockAuthCode" as NSCopying & NSObjectProtocol]
        )
        
        let mockTokenRequest = OKTTokenRequest(
            configuration: mockAuthResponse.request.configuration,
            grantType: OKTGrantTypeRefreshToken,
            authorizationCode: mockAuthResponse.authorizationCode,
            redirectURL: mockAuthResponse.request.redirectURL,
            clientID: mockAuthResponse.request.clientID,
            clientSecret: mockAuthResponse.request.clientSecret,
            scope: mockAuthResponse.scope,
            refreshToken: nil,
            codeVerifier: mockAuthResponse.request.codeVerifier,
            additionalParameters: nil
        )
        
        let mockTokenResponse = OKTTokenResponse(
            request: mockTokenRequest,
            parameters: [
                "expires_in": (expiresIn) as NSCopying & NSObjectProtocol,
                "access_token": TestUtils.mockAccessToken as NSCopying & NSObjectProtocol,
                "id_token": idToken(expired: expiredIDToken) as NSCopying & NSObjectProtocol
            ]
        )
        
        let mockAuthState = OKTTokensAuthMock(authorizationResponse: mockAuthResponse, tokenResponse: mockTokenResponse)
        mockAuthState.setShouldFailRefresh(shouldFailRefresh)
        
        return mockAuthState
    }
    
    func setShouldFailRefresh(_ shouldFail: Bool) {
        self.shouldFailRefresh = shouldFail
    }
    
    override func performAction(freshTokens action: @escaping OKTAuthStateAction) {
        if shouldFailRefresh {
            action(nil, nil, NSError(domain: "Okta Auth refresh", code: 404))
            return
        }
        
        let mockTokenRequest = OKTTokenRequest(
            configuration: lastAuthorizationResponse.request.configuration,
            grantType: OKTGrantTypeRefreshToken,
            authorizationCode: nil,
            redirectURL: nil,
            clientID: lastAuthorizationResponse.request.clientID,
            clientSecret: lastAuthorizationResponse.request.clientSecret,
            scope: nil,
            refreshToken: refreshToken,
            codeVerifier: nil,
            additionalParameters: nil
        )
        
        let mockTokenResponse = OKTTokenResponse(request: mockTokenRequest, parameters: ["refresh_token": "New Refresh Token" as NSCopying & NSObjectProtocol])
        
        update(with: mockTokenResponse, error: nil)
        
        action("Access JWT", mockTokenResponse.refreshToken, nil)
    }
    
    private static func idToken(expired: Bool) -> String {
        if expired {
            // Expired in 2019
            return """
            eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9\
            .eyJpc3MiOiJodHRwczovL2V4YW1wbGUuY29tIiwiaWF0IjoxNDIyNTM1MDA1LCJleHAiOjE1NDg3NjU0MDUsImF1ZCI6IlVuaXQgdGVzdHMiLCJzdWIiOiJleGFtcGxlQGV4YW1wbGUuY29tIn0\
            .NMvDKlInct4zuu5VMTb30ocuSSf_i8EkQTbwJTQH1RA
            """
        }
        // Expiration in 2040
        return """
        eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9\
        .eyJpc3MiOiJodHRwczovL2V4YW1wbGUuY29tIiwiaWF0IjoxNDIyNTM1MDA1LCJleHAiOjIyMTE0NTM0MDUsImF1ZCI6IlVuaXQgdGVzdHMiLCJzdWIiOiJleGFtcGxlQGV4YW1wbGUuY29tIn0\
        .2o_niz5GJdXdgXX3sl4zo1AKEVelHVJ70dqav62qlaI
        """
    }
}
