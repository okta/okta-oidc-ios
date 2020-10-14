/*! @file OKTRegistrationResponseTests.m
    @brief AppAuth iOS SDK
    @copyright
        Copyright 2016 The AppAuth for iOS Authors. All Rights Reserved.
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

#import "OKTRegistrationResponseTests.h"

#import "OKTClientMetadataParameters.h"
#import "OKTRegistrationRequestTests.h"
#import "OKTRegistrationRequest.h"
#import "OKTRegistrationResponse.h"

/*! @brief The test value for the @c clientID property.
 */
static NSString *const kClientIDTestValue = @"client1";

/*! @brief The test value for the @c clientSecretExpiresAt property.
 */
static long long const kClientSecretExpiresAtTestValue = 1463414761;

/*! @brief The test value for the @c clientSecret property.
 */
static NSString *const kClientSecretTestValue = @"secret1";

/*! @brief The test value for the @c clientIDIssuedAt property.
 */
static long long const kClientIDIssuedAtTestValue = 1463411161;

/*! @brief The test value for the @c clientRegistrationAccessToken property.
 */
static NSString *const kClientRegistrationAccessTokenTestValue = @"abcdefgh";

/*! @brief The test value for the @c registrationClientURI property.
 */
static NSString *const kRegistrationClientURITestValue = @"https://provider.example.com/client1";

/*! @brief The test value for the @c tokenEndpointAuthenticationMethod property.
 */
static NSString *const kTokenEndpointAuthMethodTestValue = @"client_secret_basic";

/*! @brief Test key for the @c additionalParameters property.
 */
static NSString *const kTestAdditionalParameterKey = @"example_parameter";

/*! @brief Test value for the @c additionalParameters property.
 */
static NSString *const kTestAdditionalParameterValue = @"example_value";

@implementation OKTRegistrationResponseTests
+ (OKTRegistrationResponse *)testInstance {
  OKTRegistrationRequest *request = [OKTRegistrationRequestTests testInstance];
  OKTRegistrationResponse *response = [[OKTRegistrationResponse alloc] initWithRequest:request
      parameters:@{
          OKTClientIDParam : kClientIDTestValue,
          OKTClientIDIssuedAtParam : @(kClientIDIssuedAtTestValue),
          OKTClientSecretParam : kClientSecretTestValue,
          OKTClientSecretExpirestAtParam : @(kClientSecretExpiresAtTestValue),
          OKTRegistrationAccessTokenParam : kClientRegistrationAccessTokenTestValue,
          OKTRegistrationClientURIParam : [NSURL URLWithString:kRegistrationClientURITestValue],
          OKTTokenEndpointAuthenticationMethodParam : kTokenEndpointAuthMethodTestValue,
          kTestAdditionalParameterKey : kTestAdditionalParameterValue
      }];
  return response;
}

/*! @brief Tests the @c NSCopying implementation by round-tripping an instance through the copying
        process and checking to make sure the source and destination instances are equivalent.
 */
- (void)testCopying {
  OKTRegistrationResponse *response = [[self class] testInstance];
  XCTAssertNotNil(response.request, @"");
  XCTAssertEqualObjects(response.clientID, kClientIDTestValue, @"");
  XCTAssertEqualObjects(response.clientIDIssuedAt,
                        [NSDate dateWithTimeIntervalSince1970:kClientIDIssuedAtTestValue], @"");
  XCTAssertEqualObjects(response.clientSecret, kClientSecretTestValue, @"");
  XCTAssertEqualObjects(response.clientSecretExpiresAt,
                        [NSDate dateWithTimeIntervalSince1970:kClientSecretExpiresAtTestValue], @"");
  XCTAssertEqualObjects(response.registrationAccessToken, kClientRegistrationAccessTokenTestValue, @"");
  XCTAssertEqualObjects(response.registrationClientURI,
                        [NSURL URLWithString:kRegistrationClientURITestValue], @"");
  XCTAssertEqualObjects(response.tokenEndpointAuthenticationMethod,
                        kTokenEndpointAuthMethodTestValue, @"");
  XCTAssertEqualObjects(response.additionalParameters[kTestAdditionalParameterKey],
                        kTestAdditionalParameterValue, @"");

  OKTRegistrationResponse *responseCopy = [response copy];

  XCTAssertNotNil(responseCopy.request, @"");
  XCTAssertEqualObjects(responseCopy.clientID, response.clientID, @"");
  XCTAssertEqualObjects(responseCopy.clientIDIssuedAt, response.clientIDIssuedAt, @"");
  XCTAssertEqualObjects(responseCopy.clientSecret, response.clientSecret, @"");
  XCTAssertEqualObjects(responseCopy.clientSecretExpiresAt, response.clientSecretExpiresAt, @"");
  XCTAssertEqualObjects(responseCopy.registrationAccessToken, response.registrationAccessToken, @"");
  XCTAssertEqualObjects(responseCopy.registrationClientURI, response.registrationClientURI, @"");
  XCTAssertEqualObjects(responseCopy.additionalParameters[kTestAdditionalParameterKey],
                        kTestAdditionalParameterValue, @"");
}

/*! @brief Tests the @c NSSecureCoding by round-tripping an instance through the coding process and
        checking to make sure the source and destination instances are equivalent.
 */
- (void)testSecureCoding {
  OKTRegistrationResponse *response = [[self class] testInstance];
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:response];
  OKTRegistrationResponse *responseCopy = [NSKeyedUnarchiver unarchiveObjectWithData:data];

  // Not a full test of the request deserialization, but should be sufficient as a smoke test
  // to make sure the request IS actually getting serialized and deserialized in the
  // NSSecureCoding implementation. We'll leave it up to the OKTAuthorizationRequest tests to make
  // sure the NSSecureCoding implementation of that class is correct.
  XCTAssertNotNil(responseCopy.request, @"");
  XCTAssertEqualObjects(responseCopy.request.applicationType, response.request.applicationType, @"");

  XCTAssertEqualObjects(responseCopy.clientID, response.clientID, @"");
  XCTAssertEqualObjects(responseCopy.clientIDIssuedAt, response.clientIDIssuedAt, @"");
  XCTAssertEqualObjects(responseCopy.clientSecret, response.clientSecret, @"");
  XCTAssertEqualObjects(responseCopy.clientSecretExpiresAt, response.clientSecretExpiresAt, @"");
  XCTAssertEqualObjects(responseCopy.registrationAccessToken, response.registrationAccessToken, @"");
  XCTAssertEqualObjects(responseCopy.registrationClientURI, response.registrationClientURI, @"");
  XCTAssertEqualObjects(responseCopy.tokenEndpointAuthenticationMethod,
                        response.tokenEndpointAuthenticationMethod, @"");
  XCTAssertEqualObjects(responseCopy.additionalParameters[kTestAdditionalParameterKey],
                        kTestAdditionalParameterValue, @"");
}

/*! @brief Make sure the registration response is verified to ensure the 'client_secret_expires_at'
        parameter exists if a 'client_secret' is issued.
    @see https://openid.net/specs/openid-connect-registration-1_0.html#RegistrationResponse
 */
- (void)testMissingClientSecretExpiresAtWithClientSecret {
  OKTRegistrationRequest *request = [OKTRegistrationRequestTests testInstance];
  OKTRegistrationResponse *response = [[OKTRegistrationResponse alloc] initWithRequest:request
      parameters:@{
          OKTClientIDParam : kClientIDTestValue,
          OKTClientSecretParam : kClientSecretTestValue,
      }];
  XCTAssertNil(response, @"");
}

/*! @brief Make sure the registration response missing 'registration_access_token' is detected when
        'client_registration_uri' is specified..
    @see https://openid.net/specs/openid-connect-registration-1_0.html#RegistrationResponse
 */
- (void)testMissingRegistrationAccessTokenWithRegistrationClientURI {
  OKTRegistrationRequest *request = [OKTRegistrationRequestTests testInstance];
  OKTRegistrationResponse *response = [[OKTRegistrationResponse alloc] initWithRequest:request
      parameters:@{
          OKTClientIDParam : kClientIDTestValue,
          OKTRegistrationClientURIParam : [NSURL URLWithString:kRegistrationClientURITestValue]
      }];
  XCTAssertNil(response, @"");
}

/*! @brief Make sure the registration response missing 'client_registration_uri' is detected when
        'registration_access_token' is specified..
    @see https://openid.net/specs/openid-connect-registration-1_0.html#RegistrationResponse
 */
- (void)testMissingRegistrationClientURIWithRegistrationAccessToken {
  OKTRegistrationRequest *request = [OKTRegistrationRequestTests testInstance];
  OKTRegistrationResponse *response = [[OKTRegistrationResponse alloc] initWithRequest:request
      parameters:@{
          OKTClientIDParam : kClientIDTestValue,
          OKTRegistrationAccessTokenParam : kClientRegistrationAccessTokenTestValue
      }];
  XCTAssertNil(response, @"");
}

@end
