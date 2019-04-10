import XCTest

@testable import OktaOidc

class OktaOidcEndpointTests: XCTestCase {

    func testGetURI_Introspection() {
        let testEndpoint = "http://test.endpoint.com"
        
        let testIssuer = "http://test.issuer.com"
        let expectedEndpointBasedOnIssuer = testIssuer + "/oauth2/v1/" + "introspect"
    
        XCTAssertNil(OktaOidcEndpoint.introspection.getURL(discoveredMetadata: nil, issuer: nil))
        XCTAssertNil(OktaOidcEndpoint.introspection.getURL(discoveredMetadata: ["invalidKey" : testEndpoint], issuer: nil))
        
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
        XCTAssertNil(OktaOidcEndpoint.revocation.getURL(discoveredMetadata: ["invalidKey" : testEndpoint], issuer: nil))
        
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
        XCTAssertNil(OktaOidcEndpoint.userInfo.getURL(discoveredMetadata: ["invalidKey" : testEndpoint], issuer: nil))
        
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
            OktaOidcError.noIntrospectionEndpoint.localizedDescription,
            OktaOidcEndpoint.introspection.noEndpointError.localizedDescription
        )
        
        XCTAssertEqual(
            OktaOidcError.noRevocationEndpoint.localizedDescription,
            OktaOidcEndpoint.revocation.noEndpointError.localizedDescription
        )
        
        XCTAssertEqual(
            OktaOidcError.noUserInfoEndpoint.localizedDescription,
            OktaOidcEndpoint.userInfo.noEndpointError.localizedDescription
        )
    }

}
