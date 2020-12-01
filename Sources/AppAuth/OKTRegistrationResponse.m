/*! @file OKTRegistrationResponse.m
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

#import "OKTRegistrationResponse.h"

#import "OKTClientMetadataParameters.h"
#import "OKTDefines.h"
#import "OKTFieldMapping.h"
#import "OKTRegistrationRequest.h"
#import "OKTTokenUtilities.h"

NSString *const OKTClientIDParam = @"client_id";
NSString *const OKTClientIDIssuedAtParam = @"client_id_issued_at";
NSString *const OKTClientSecretParam = @"client_secret";
NSString *const OKTClientSecretExpirestAtParam = @"client_secret_expires_at";
NSString *const OKTRegistrationAccessTokenParam = @"registration_access_token";
NSString *const OKTRegistrationClientURIParam = @"registration_client_uri";

/*! @brief Key used to encode the @c request property for @c NSSecureCoding
 */
static NSString *const kRequestKey = @"request";

/*! @brief Key used to encode the @c additionalParameters property for @c NSSecureCoding
 */
static NSString *const kAdditionalParametersKey = @"additionalParameters";

@implementation OKTRegistrationResponse

/*! @brief Returns a mapping of incoming parameters to instance variables.
    @return A mapping of incoming parameters to instance variables.
 */
+ (NSDictionary<NSString *, OKTFieldMapping *> *)fieldMap {
  static NSMutableDictionary<NSString *, OKTFieldMapping *> *fieldMap;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    fieldMap = [NSMutableDictionary dictionary];
    fieldMap[OKTClientIDParam] = [[OKTFieldMapping alloc] initWithName:@"_clientID"
                                                                  type:[NSString class]];
    fieldMap[OKTClientIDIssuedAtParam] =
    [[OKTFieldMapping alloc] initWithName:@"_clientIDIssuedAt"
                                     type:[NSDate class]
                               conversion:[OKTFieldMapping dateEpochConversion]];
    fieldMap[OKTClientSecretParam] =
    [[OKTFieldMapping alloc] initWithName:@"_clientSecret"
                                     type:[NSString class]];
    fieldMap[OKTClientSecretExpirestAtParam] =
    [[OKTFieldMapping alloc] initWithName:@"_clientSecretExpiresAt"
                                     type:[NSDate class]
                               conversion:[OKTFieldMapping dateEpochConversion]];
    fieldMap[OKTRegistrationAccessTokenParam] =
    [[OKTFieldMapping alloc] initWithName:@"_registrationAccessToken"
                                     type:[NSString class]];
    fieldMap[OKTRegistrationClientURIParam] =
    [[OKTFieldMapping alloc] initWithName:@"_registrationClientURI"
                                     type:[NSURL class]
                               conversion:[OKTFieldMapping URLConversion]];
    fieldMap[OKTTokenEndpointAuthenticationMethodParam] =
    [[OKTFieldMapping alloc] initWithName:@"_tokenEndpointAuthenticationMethod"
                                     type:[NSString class]];
  });
  return fieldMap;
}


#pragma mark - Initializers

- (nonnull instancetype)init
  OKT_UNAVAILABLE_USE_INITIALIZER(@selector(initWithRequest:parameters:))

- (instancetype)initWithRequest:(OKTRegistrationRequest *)request
                              parameters:(NSDictionary<NSString *, NSObject <NSCopying> *> *)parameters {
  self = [super init];
  if (self) {
    _request = [request copy];
    NSDictionary<NSString *, NSObject <NSCopying> *> *additionalParameters =
    [OKTFieldMapping remainingParametersWithMap:[[self class] fieldMap]
                                     parameters:parameters
                                       instance:self];
    _additionalParameters = additionalParameters;

    if ((_clientSecret && !_clientSecretExpiresAt)
        || (!!_registrationClientURI != !!_registrationAccessToken)) {
      // If client_secret is issued, client_secret_expires_at is REQUIRED,
      // and the response MUST contain "[...] both a Client Configuration Endpoint
      // and a Registration Access Token or neither of them"
      return nil;
    }
  }
  return self;
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(nullable NSZone *)zone {
  // The documentation for NSCopying specifically advises us to return a reference to the original
  // instance in the case where instances are immutable (as ours is):
  // "Implement NSCopying by retaining the original instead of creating a new copy when the class
  // and its contents are immutable."
  return self;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
  OKTRegistrationRequest *request = [aDecoder decodeObjectOfClass:[OKTRegistrationRequest class]
                                                           forKey:kRequestKey];
  self = [self initWithRequest:request
                    parameters:@{}];
  if (self) {
    [OKTFieldMapping decodeWithCoder:aDecoder
                                 map:[[self class] fieldMap]
                            instance:self];
    _additionalParameters = [aDecoder decodeObjectOfClasses:[OKTFieldMapping JSONTypes]
                                                     forKey:kAdditionalParametersKey];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [OKTFieldMapping encodeWithCoder:aCoder map:[[self class] fieldMap] instance:self];
  [aCoder encodeObject:_request forKey:kRequestKey];
  [aCoder encodeObject:_additionalParameters forKey:kAdditionalParametersKey];
}

#pragma mark - NSObject overrides

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, clientID: \"%@\", clientIDIssuedAt: %@, "
          "clientSecret: %@, clientSecretExpiresAt: \"%@\", "
          "registrationAccessToken: \"%@\", "
          "registrationClientURI: \"%@\", "
          "additionalParameters: %@, request: %@>",
          NSStringFromClass([self class]),
          (void *)self,
          _clientID,
          _clientIDIssuedAt,
          [OKTTokenUtilities redact:_clientSecret],
          _clientSecretExpiresAt,
          [OKTTokenUtilities redact:_registrationAccessToken],
          _registrationClientURI,
          _additionalParameters,
          _request];
}

@end
