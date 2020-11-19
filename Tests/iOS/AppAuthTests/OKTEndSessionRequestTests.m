/*! @file OKTServiceDiscoveryTests.m
    @brief AppAuth iOS SDK
    @copyright
        Copyright 2017 The AppAuth Authors. All Rights Reserved.
    @copydetails
        Licensed under the Apache License, Version 2.0 (the "License");
        you may not use this file except in compliance with the License.
        You may obtain a copy of the License at
 
        http://www.apache.org/licenses/LICENSE-2.0
 
        Unless required by applicable law or agreed to in writing, software
        distributed under the License is distributed on an "AS IS" BASIS,
        WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
        See the License for the specific language governing permissions and
        limitations under the License.
    @modifications
        Copyright (C) 2019 Okta Inc.
 */

#import "OKTEndSessionRequestTests.h"

#import "OKTServiceDiscoveryTests.h"
#import "OKTEndSessionRequest.h"
#import "OKTServiceConfiguration.h"
#import "OKTServiceDiscovery.h"

/*! @brief Test value for the @c redirectURL property.
 */
static NSString *const kTestRedirectURL = @"http://www.google.com/";

/*! @brief Test key for the @c additionalParameters property.
 */
static NSString *const kTestAdditionalParameterKey = @"A";

/*! @brief Test value for the @c additionalParameters property.
 */
static NSString *const kTestAdditionalParameterValue = @"1";

/*! @brief Test value for the @c state property.
 */
static NSString *const kTestState = @"State";

/*! @brief Test value for the @c idTokenHint property.
 */
static NSString *const kTestIdTokenHint = @"id-token-hint";

@implementation OKTEndSessionRequestTests

+ (OKTEndSessionRequest *)testInstance {
    NSDictionary *additionalParameters =
        @{ kTestAdditionalParameterKey : kTestAdditionalParameterValue };

    OKTServiceDiscovery *discoveryDocument = [[OKTServiceDiscovery alloc] initWithDictionary:[OKTServiceDiscoveryTests completeServiceDiscoveryDictionary] error:nil];
    OKTServiceConfiguration *configuration = [[OKTServiceConfiguration alloc] initWithDiscoveryDocument:discoveryDocument];

    return [[OKTEndSessionRequest alloc] initWithConfiguration:configuration
                                               idTokenHint:kTestIdTokenHint
                                     postLogoutRedirectURL:[NSURL URLWithString:kTestRedirectURL]
                                                     state:kTestState
                                      additionalParameters:additionalParameters];
}

/*! @brief Tests the @c NSCopying implementation by round-tripping an instance through the copying
 process and checking to make sure the source and destination instances are equivalent.
 */
- (void)testCopying {
    OKTEndSessionRequest *request = [[self class] testInstance];

    XCTAssertEqualObjects(request.idTokenHint, kTestIdTokenHint);
    XCTAssertEqualObjects(request.postLogoutRedirectURL, [NSURL URLWithString:kTestRedirectURL]);
    XCTAssertEqualObjects(request.state, kTestState);
    XCTAssertEqualObjects(request.additionalParameters[kTestAdditionalParameterKey],
                          kTestAdditionalParameterValue);

    OKTEndSessionRequest *requestCopy = [request copy];

    XCTAssertNotNil(requestCopy.configuration);
    XCTAssertEqualObjects(requestCopy.configuration, request.configuration);
    XCTAssertEqualObjects(requestCopy.postLogoutRedirectURL, request.postLogoutRedirectURL);
    XCTAssertEqualObjects(requestCopy.state, request.state);
    XCTAssertEqualObjects(requestCopy.idTokenHint, request.idTokenHint);
}

/*! @brief Tests the @c NSSecureCoding by round-tripping an instance through the coding process and
 checking to make sure the source and destination instances are equivalent.
 */
- (void)testSecureCoding {
    OKTEndSessionRequest *request = [[self class] testInstance];

    XCTAssertEqualObjects(request.idTokenHint, kTestIdTokenHint);
    XCTAssertEqualObjects(request.postLogoutRedirectURL, [NSURL URLWithString:kTestRedirectURL]);
    XCTAssertEqualObjects(request.state, kTestState);
    XCTAssertEqualObjects(request.additionalParameters[kTestAdditionalParameterKey],
                          kTestAdditionalParameterValue);

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:request];
    OKTEndSessionRequest *requestCopy = [NSKeyedUnarchiver unarchiveObjectWithData:data];

    XCTAssertNotNil(requestCopy.configuration);
    XCTAssertEqualObjects(requestCopy.configuration.authorizationEndpoint,
                          request.configuration.authorizationEndpoint);
    XCTAssertEqualObjects(requestCopy.postLogoutRedirectURL, request.postLogoutRedirectURL);
    XCTAssertEqualObjects(requestCopy.state, request.state);
    XCTAssertEqualObjects(requestCopy.idTokenHint, request.idTokenHint);
}

- (void)testLogoutRequestURL {
    OKTEndSessionRequest *request = [[self class] testInstance];
    NSURL *endSessionRequestURL = request.endSessionRequestURL;

    NSURLComponents *components = [NSURLComponents componentsWithString:endSessionRequestURL.absoluteString];

    XCTAssertTrue([endSessionRequestURL.absoluteString hasPrefix:@"https://www.example.com/logout"]);

    NSMutableDictionary<NSString *, NSString*> *query = [[NSMutableDictionary alloc] init];
    for (NSURLQueryItem *queryItem in components.queryItems) {
        query[queryItem.name] = queryItem.value;
    }

    XCTAssertEqualObjects(query[@"state"], kTestState);
    XCTAssertEqualObjects(query[@"id_token_hint"], kTestIdTokenHint);
    XCTAssertEqualObjects(query[@"post_logout_redirect_uri"], kTestRedirectURL);
}

@end
