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

import XCTest

@testable import OktaOidc

class OktaOidcEndpointTests: XCTestCase {

    func testGetURI_Introspection() {
        let testEndpoint = "http://test.endpoint.com"
        
        let testIssuer = "http://test.issuer.com"
        let expectedEndpointBasedOnIssuer = testIssuer + "/oauth2/v1/" + "introspect"
    
        XCTAssertNil(OktaOidcEndpoint.introspection.getURL(discoveredMetadata: nil, issuer: nil))
        XCTAssertNil(OktaOidcEndpoint.introspection.getURL(discoveredMetadata: ["invalidKey": testEndpoint], issuer: nil))
        
        XCTAssertEqual(
            URL(string: testEndpoint),
            OktaOidcEndpoint.introspection.getURL(discoveredMetadata: ["introspection_endpoint": testEndpoint], issuer: nil)
        )
        XCTAssertEqual(
            URL(string: testEndpoint),
            OktaOidcEndpoint.introspection.getURL(discoveredMetadata: ["introspection_endpoint": testEndpoint], issuer: testIssuer)
        )
        
        XCTAssertEqual(
            URL(string: (expectedEndpointBasedOnIssuer)),
            OktaOidcEndpoint.introspection.getURL(discoveredMetadata: nil, issuer: testIssuer)
        )
        XCTAssertEqual(
            URL(string: (expectedEndpointBasedOnIssuer)),
            OktaOidcEndpoint.introspection.getURL(discoveredMetadata: nil, issuer: testIssuer + "/")
        )
        XCTAssertEqual(
            URL(string: (expectedEndpointBasedOnIssuer)),
            OktaOidcEndpoint.introspection.getURL(discoveredMetadata: nil, issuer: testIssuer + "/oauth2")
        )
        XCTAssertEqual(
            URL(string: (expectedEndpointBasedOnIssuer)),
            OktaOidcEndpoint.introspection.getURL(discoveredMetadata: nil, issuer: testIssuer + "/oauth2/")
        )
    }

    func testGetURI_Revocation() {
        let testEndpoint = "http://test.endpoint.com"
        
        let testIssuer = "http://test.issuer.com"
        let expectedEndpointBasedOnIssuer = testIssuer + "/oauth2/v1/" + "revoke"
    
        XCTAssertNil(OktaOidcEndpoint.revocation.getURL(discoveredMetadata: nil, issuer: nil))
        XCTAssertNil(OktaOidcEndpoint.revocation.getURL(discoveredMetadata: ["invalidKey": testEndpoint], issuer: nil))
        
        XCTAssertEqual(
            URL(string: testEndpoint),
            OktaOidcEndpoint.revocation.getURL(discoveredMetadata: ["revocation_endpoint": testEndpoint], issuer: nil)
        )
        XCTAssertEqual(
            URL(string: testEndpoint),
            OktaOidcEndpoint.revocation.getURL(discoveredMetadata: ["revocation_endpoint": testEndpoint], issuer: testIssuer)
        )
        
        XCTAssertEqual(
            URL(string: (expectedEndpointBasedOnIssuer)),
            OktaOidcEndpoint.revocation.getURL(discoveredMetadata: nil, issuer: testIssuer)
        )
        XCTAssertEqual(
            URL(string: (expectedEndpointBasedOnIssuer)),
            OktaOidcEndpoint.revocation.getURL(discoveredMetadata: nil, issuer: testIssuer + "/")
        )
        XCTAssertEqual(
            URL(string: (expectedEndpointBasedOnIssuer)),
            OktaOidcEndpoint.revocation.getURL(discoveredMetadata: nil, issuer: testIssuer + "/oauth2")
        )
        XCTAssertEqual(
            URL(string: (expectedEndpointBasedOnIssuer)),
            OktaOidcEndpoint.revocation.getURL(discoveredMetadata: nil, issuer: testIssuer + "/oauth2/")
        )
    }
    
    func testGetURI_UserInfo() {
        let testEndpoint = "http://test.endpoint.com"
        
        let testIssuer = "http://test.issuer.com"
        let expectedEndpointBasedOnIssuer = testIssuer + "/oauth2/v1/" + "userinfo"
    
        XCTAssertNil(OktaOidcEndpoint.userInfo.getURL(discoveredMetadata: nil, issuer: nil))
        XCTAssertNil(OktaOidcEndpoint.userInfo.getURL(discoveredMetadata: ["invalidKey": testEndpoint], issuer: nil))
        
        XCTAssertEqual(
            URL(string: testEndpoint),
            OktaOidcEndpoint.userInfo.getURL(discoveredMetadata: ["userinfo_endpoint": testEndpoint], issuer: nil)
        )
        XCTAssertEqual(
            URL(string: testEndpoint),
            OktaOidcEndpoint.userInfo.getURL(discoveredMetadata: ["userinfo_endpoint": testEndpoint], issuer: testIssuer)
        )
        
        XCTAssertEqual(
            URL(string: (expectedEndpointBasedOnIssuer)),
            OktaOidcEndpoint.userInfo.getURL(discoveredMetadata: nil, issuer: testIssuer)
        )
        XCTAssertEqual(
            URL(string: (expectedEndpointBasedOnIssuer)),
            OktaOidcEndpoint.userInfo.getURL(discoveredMetadata: nil, issuer: testIssuer + "/")
        )
        XCTAssertEqual(
            URL(string: (expectedEndpointBasedOnIssuer)),
            OktaOidcEndpoint.userInfo.getURL(discoveredMetadata: nil, issuer: testIssuer + "/oauth2")
        )
        XCTAssertEqual(
            URL(string: (expectedEndpointBasedOnIssuer)),
            OktaOidcEndpoint.userInfo.getURL(discoveredMetadata: nil, issuer: testIssuer + "/oauth2/")
        )
    }

    func testNoEndpointError() {
        XCTAssertEqual(
            OktaOidcError.noIntrospectionEndpoint,
            OktaOidcEndpoint.introspection.noEndpointError
        )
        
        XCTAssertEqual(
            OktaOidcError.noRevocationEndpoint,
            OktaOidcEndpoint.revocation.noEndpointError
        )
        
        XCTAssertEqual(
            OktaOidcError.noUserInfoEndpoint,
            OktaOidcEndpoint.userInfo.noEndpointError
        )
    }

}
