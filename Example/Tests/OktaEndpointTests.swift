import XCTest

@testable import OktaAuth

class OktaEndpointTests: XCTestCase {

    func testGetURI_Introspection() {
        let testEndpoint = "http://test.endpoint.com"
        
        let testIssuer = "http://test.issuer.com"
        let expectedEndpointBasedOnIssuer = testIssuer + "/oauth2/v1/" + "introspect"
    
        XCTAssertNil(OktaEndpoint.introspection.getURL(discoveredMetadata: nil, issuer: nil))
        XCTAssertNil(OktaEndpoint.introspection.getURL(discoveredMetadata: ["invalidKey" : testEndpoint], issuer: nil))
        
        XCTAssertEqual(
            URL(string: testEndpoint),
            OktaEndpoint.introspection.getURL(discoveredMetadata: ["introspection_endpoint": testEndpoint], issuer: nil)
        )
        XCTAssertEqual(
            URL(string: testEndpoint),
            OktaEndpoint.introspection.getURL(discoveredMetadata: ["introspection_endpoint": testEndpoint], issuer: testIssuer)
        )
        
        XCTAssertEqual(
            URL(string: (expectedEndpointBasedOnIssuer)),
            OktaEndpoint.introspection.getURL(discoveredMetadata: nil, issuer: testIssuer)
        )
        XCTAssertEqual(
            URL(string: (expectedEndpointBasedOnIssuer)),
            OktaEndpoint.introspection.getURL(discoveredMetadata: nil, issuer: testIssuer + "/")
        )
        XCTAssertEqual(
            URL(string: (expectedEndpointBasedOnIssuer)),
            OktaEndpoint.introspection.getURL(discoveredMetadata: nil, issuer: testIssuer + "/oauth2")
        )
        XCTAssertEqual(
            URL(string: (expectedEndpointBasedOnIssuer)),
            OktaEndpoint.introspection.getURL(discoveredMetadata: nil, issuer: testIssuer + "/oauth2/")
        )
    }

    func testGetURI_Revocation() {
        let testEndpoint = "http://test.endpoint.com"
        
        let testIssuer = "http://test.issuer.com"
        let expectedEndpointBasedOnIssuer = testIssuer + "/oauth2/v1/" + "revoke"
    
        XCTAssertNil(OktaEndpoint.revocation.getURL(discoveredMetadata: nil, issuer: nil))
        XCTAssertNil(OktaEndpoint.revocation.getURL(discoveredMetadata: ["invalidKey" : testEndpoint], issuer: nil))
        
        XCTAssertEqual(
            URL(string: testEndpoint),
            OktaEndpoint.revocation.getURL(discoveredMetadata: ["revocation_endpoint": testEndpoint], issuer: nil)
        )
        XCTAssertEqual(
            URL(string: testEndpoint),
            OktaEndpoint.revocation.getURL(discoveredMetadata: ["revocation_endpoint": testEndpoint], issuer: testIssuer)
        )
        
        XCTAssertEqual(
            URL(string: (expectedEndpointBasedOnIssuer)),
            OktaEndpoint.revocation.getURL(discoveredMetadata: nil, issuer: testIssuer)
        )
        XCTAssertEqual(
            URL(string: (expectedEndpointBasedOnIssuer)),
            OktaEndpoint.revocation.getURL(discoveredMetadata: nil, issuer: testIssuer + "/")
        )
        XCTAssertEqual(
            URL(string: (expectedEndpointBasedOnIssuer)),
            OktaEndpoint.revocation.getURL(discoveredMetadata: nil, issuer: testIssuer + "/oauth2")
        )
        XCTAssertEqual(
            URL(string: (expectedEndpointBasedOnIssuer)),
            OktaEndpoint.revocation.getURL(discoveredMetadata: nil, issuer: testIssuer + "/oauth2/")
        )
    }
    
    func testGetURI_UserInfo() {
        let testEndpoint = "http://test.endpoint.com"
        
        let testIssuer = "http://test.issuer.com"
        let expectedEndpointBasedOnIssuer = testIssuer + "/oauth2/v1/" + "userinfo"
    
        XCTAssertNil(OktaEndpoint.userInfo.getURL(discoveredMetadata: nil, issuer: nil))
        XCTAssertNil(OktaEndpoint.userInfo.getURL(discoveredMetadata: ["invalidKey" : testEndpoint], issuer: nil))
        
        XCTAssertEqual(
            URL(string: testEndpoint),
            OktaEndpoint.userInfo.getURL(discoveredMetadata: ["userinfo_endpoint": testEndpoint], issuer: nil)
        )
        XCTAssertEqual(
            URL(string: testEndpoint),
            OktaEndpoint.userInfo.getURL(discoveredMetadata: ["userinfo_endpoint": testEndpoint], issuer: testIssuer)
        )
        
        XCTAssertEqual(
            URL(string: (expectedEndpointBasedOnIssuer)),
            OktaEndpoint.userInfo.getURL(discoveredMetadata: nil, issuer: testIssuer)
        )
        XCTAssertEqual(
            URL(string: (expectedEndpointBasedOnIssuer)),
            OktaEndpoint.userInfo.getURL(discoveredMetadata: nil, issuer: testIssuer + "/")
        )
        XCTAssertEqual(
            URL(string: (expectedEndpointBasedOnIssuer)),
            OktaEndpoint.userInfo.getURL(discoveredMetadata: nil, issuer: testIssuer + "/oauth2")
        )
        XCTAssertEqual(
            URL(string: (expectedEndpointBasedOnIssuer)),
            OktaEndpoint.userInfo.getURL(discoveredMetadata: nil, issuer: testIssuer + "/oauth2/")
        )
    }

    func testNoEndpointError() {
        XCTAssertEqual(
            OktaError.noIntrospectionEndpoint.localizedDescription,
            OktaEndpoint.introspection.noEndpointError.localizedDescription
        )
        
        XCTAssertEqual(
            OktaError.noRevocationEndpoint.localizedDescription,
            OktaEndpoint.revocation.noEndpointError.localizedDescription
        )
        
        XCTAssertEqual(
            OktaError.noUserInfoEndpoint.localizedDescription,
            OktaEndpoint.userInfo.noEndpointError.localizedDescription
        )
    }

}
