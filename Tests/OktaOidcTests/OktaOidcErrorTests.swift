/*
 * Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
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
import XCTest

#if SWIFT_PACKAGE
@testable import TestCommon
#endif

final class OktaOidcErrorTests: XCTestCase {
    
    func testGeneralOidcError() {
        let error = OktaOidcError.JWTDecodeError as NSError

        XCTAssertEqual(error.code, OktaOidcError.generalErrorCode)
        XCTAssertEqual(error.domain, OktaOidcError.errorDomain)
        XCTAssertEqual(error.userInfo[NSLocalizedDescriptionKey] as! String, error.localizedDescription)
        XCTAssertNil(error.userInfo[NSUnderlyingErrorKey] as? NSError)
        
        if #available(iOS 14.5, macOS 11.3, *) {
            XCTAssertTrue(error.underlyingErrors.isEmpty)
        }
    }
    
    func testApiError() {
        let underlyingError = NSError(domain: NSURLErrorDomain,
                                      code: NSURLErrorNetworkConnectionLost,
                                      userInfo: [NSLocalizedDescriptionKey: "Localization error description"])
        let error = OktaOidcError.api(message: "Mock error", underlyingError: underlyingError) as NSError
        
        XCTAssertEqual(error.domain, OktaOidcError.errorDomain)
        XCTAssertEqual(error.code, underlyingError.code)
        XCTAssertEqual(error.userInfo[NSUnderlyingErrorKey] as! NSError, underlyingError)
        XCTAssertEqual(error.userInfo[NSLocalizedDescriptionKey] as! String, error.localizedDescription)
        
        if #available(iOS 14.5, macOS 11.3, *) {
            XCTAssertEqual(error.underlyingErrors.first! as NSError, underlyingError)
        }
    }
    
    func testApiErrorWithoutUnderlyingError() {
        let error = OktaOidcError.api(message: "Mock error", underlyingError: nil) as NSError
        
        XCTAssertEqual(error.domain, OktaOidcError.errorDomain)
        XCTAssertEqual(error.code, OktaOidcError.generalErrorCode)
        XCTAssertNil(error.userInfo[NSUnderlyingErrorKey] as? NSError)
        XCTAssertEqual(error.userInfo[NSLocalizedDescriptionKey] as! String, error.localizedDescription)
        
        if #available(iOS 14.5, macOS 11.3, *) {
            XCTAssertTrue(error.underlyingErrors.isEmpty)
        }
    }
    
    func testAuthCodeResponseError() {
        let error = OktaOidcError.unexpectedAuthCodeResponse(statusCode: 404) as NSError
        
        XCTAssertEqual(error.domain, OktaOidcError.errorDomain)
        XCTAssertEqual(error.code, 404)
        XCTAssertNil(error.userInfo[NSUnderlyingErrorKey] as? NSError)
        XCTAssertEqual(error.userInfo[NSLocalizedDescriptionKey] as! String, error.localizedDescription)
    }
    
    func testErrorsEquatability() {
        // unexpectedAuthCodeResponse
        let lhsAuthCodeResponse = OktaOidcError.unexpectedAuthCodeResponse(statusCode: NSURLErrorCannotLoadFromNetwork)
        let rhsAuthCodeResponse = OktaOidcError.unexpectedAuthCodeResponse(statusCode: NSURLErrorCannotLoadFromNetwork)
        
        XCTAssertEqual(lhsAuthCodeResponse, rhsAuthCodeResponse)
        XCTAssertEqual(lhsAuthCodeResponse as NSError, rhsAuthCodeResponse as NSError)
        XCTAssertNotEqual(lhsAuthCodeResponse, .unexpectedAuthCodeResponse(statusCode: 123))
        XCTAssertNotEqual(lhsAuthCodeResponse, .noPListGiven)
        
        // api
        let underlyingError = NSError(domain: NSURLErrorDomain,
                                      code: NSURLErrorNetworkConnectionLost,
                                      userInfo: [NSLocalizedDescriptionKey: "Localization error description"])
        let lhsApiError = OktaOidcError.api(message: "Mock error", underlyingError: underlyingError)
        let rhsApiError = OktaOidcError.api(message: "Mock error", underlyingError: underlyingError)
        
        XCTAssertEqual(lhsApiError, rhsApiError)
        XCTAssertEqual(lhsApiError as NSError, rhsApiError as NSError)
        XCTAssertNotEqual(lhsApiError, .api(message: "Mock error", underlyingError: nil))
        XCTAssertNotEqual(lhsApiError, .JWTDecodeError)
        
        // authorization
        let rhsAuthorization = OktaOidcError.authorization(error: "Error", description: "Localized Description")
        let lhsAuthorization = OktaOidcError.authorization(error: "Error", description: "Localized Description")
        
        XCTAssertEqual(rhsAuthorization, lhsAuthorization)
        XCTAssertEqual(rhsAuthorization as NSError, lhsAuthorization as NSError)
        XCTAssertNotEqual(rhsAuthorization, .authorization(error: "Error", description: "Localized Description (2)"))
        XCTAssertNotEqual(.missingConfigurationValues, lhsAuthorization)
        
        // errorFetchingFreshTokens
        let rhsFetchingFreshTokens = OktaOidcError.errorFetchingFreshTokens("Fetch Error")
        let lhsFetchingFreshTokens = OktaOidcError.errorFetchingFreshTokens("Fetch Error")
        XCTAssertEqual(rhsFetchingFreshTokens, lhsFetchingFreshTokens)
        XCTAssertEqual(rhsFetchingFreshTokens as NSError, lhsFetchingFreshTokens as NSError)
        XCTAssertNotEqual(rhsFetchingFreshTokens, .errorFetchingFreshTokens("Fetch Error (2)"))
        XCTAssertNotEqual(.noBearerToken, rhsFetchingFreshTokens)
    }
}
