/*! @file OKTEndSessionRequest.m
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

#import "OKTEndSessionRequest.h"

#import "OKTDefines.h"
#import "OKTTokenUtilities.h"
#import "OKTServiceConfiguration.h"
#import "OKTServiceDiscovery.h"
#import "OKTURLQueryComponent.h"

/*! @brief The key for the @c configuration property for @c NSSecureCoding
 */
static NSString *const kConfigurationKey = @"configuration";

/*! @brief Key used to encode the @c state property for @c NSSecureCoding, and on the URL request.
 */
static NSString *const kStateKey = @"state";

/*! @brief Key used to encode the @c postLogoutRedirectURL property for @c NSSecureCoding, and on the URL request.
 */
static NSString *const kPostLogoutRedirectURLKey = @"post_logout_redirect_uri";

/*! @brief Key used to encode the @c idTokenHint property for @c NSSecureCoding, and on the URL request.
 */
static NSString *const kIdTokenHintKey = @"id_token_hint";

/*! @brief Key used to encode the @c additionalParameters property for @c NSSecureCoding
 */
static NSString *const kAdditionalParametersKey = @"additionalParameters";

/*! @brief Number of random bytes generated for the @state.
 */
static NSUInteger const kStateSizeBytes = 32;

/*! @brief Assertion text for missing end_session_endpoint.
 */
static NSString *const OKTMissingEndSessionEndpointMessage =
@"The service configuration is missing an end_session_endpoint.";

@implementation OKTEndSessionRequest

- (instancetype)init
    OKT_UNAVAILABLE_USE_INITIALIZER(
        @selector(initWithConfiguration:
                            idTokenHint:
                  postLogoutRedirectURL:
                   additionalParameters:)
    )

- (instancetype)initWithConfiguration:(OKTServiceConfiguration *)configuration
                          idTokenHint:(NSString *)idTokenHint
                postLogoutRedirectURL:(NSURL *)postLogoutRedirectURL
                                state:(NSString *)state
                 additionalParameters:(NSDictionary<NSString *,NSString *> *)additionalParameters
{
  self = [super init];
  if (self) {
      _configuration = [configuration copy];
      _idTokenHint = [idTokenHint copy];
      _postLogoutRedirectURL = [postLogoutRedirectURL copy];
      _state = [state copy];
      _additionalParameters =
          [[NSDictionary alloc] initWithDictionary:additionalParameters copyItems:YES];
  }
  return self;
}

- (instancetype)initWithConfiguration:(OKTServiceConfiguration *)configuration
                          idTokenHint:(NSString *)idTokenHint
                postLogoutRedirectURL:(NSURL *)postLogoutRedirectURL
                 additionalParameters:(NSDictionary<NSString *,NSString *> *)additionalParameters
{
  return [self initWithConfiguration:configuration
                         idTokenHint:idTokenHint
               postLogoutRedirectURL:postLogoutRedirectURL
                               state:[[self class] generateState]
                additionalParameters:additionalParameters];
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

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  OKTServiceConfiguration *configuration = [aDecoder decodeObjectOfClass:[OKTServiceConfiguration class] forKey:kConfigurationKey];

  NSString *idTokenHint = [aDecoder decodeObjectOfClass:[NSString class] forKey:kIdTokenHintKey];
  NSURL *postLogoutRedirectURL = [aDecoder decodeObjectOfClass:[NSURL class] forKey:kPostLogoutRedirectURLKey];
  NSString *state = [aDecoder decodeObjectOfClass:[NSString class] forKey:kStateKey];
  NSSet *additionalParameterCodingClasses = [NSSet setWithArray:@[
                                                                  [NSDictionary class],
                                                                  [NSString class]
                                                                  ]];
  NSDictionary *additionalParameters = [aDecoder decodeObjectOfClasses:additionalParameterCodingClasses
                           forKey:kAdditionalParametersKey];

  self = [self initWithConfiguration:configuration
                         idTokenHint:idTokenHint
               postLogoutRedirectURL:postLogoutRedirectURL
                               state:state
                additionalParameters:additionalParameters];
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:_configuration forKey:kConfigurationKey];
  [aCoder encodeObject:_idTokenHint forKey:kIdTokenHintKey];
  [aCoder encodeObject:_postLogoutRedirectURL forKey:kPostLogoutRedirectURLKey];
  [aCoder encodeObject:_state forKey:kStateKey];
  [aCoder encodeObject:_additionalParameters forKey:kAdditionalParametersKey];
}

#pragma mark - NSObject overrides

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, request: %@>",
          NSStringFromClass([self class]),
          (void *)self,
          self.endSessionRequestURL];
}

+ (nullable NSString *)generateState {
  return [OKTTokenUtilities randomURLSafeStringWithSize:kStateSizeBytes];
}

#pragma mark - OKTExternalUserAgentRequest

- (NSURL*)externalUserAgentRequestURL {
  return [self endSessionRequestURL];
}

- (NSString *)redirectScheme {
  return [_postLogoutRedirectURL scheme];
}

#pragma mark -

- (NSURL *)endSessionRequestURL {
  OKTURLQueryComponent *query = [[OKTURLQueryComponent alloc] init];

  // Add any additional parameters the client has specified.
  [query addParameters:_additionalParameters];

  // Add optional parameters, as applicable.
  if (_idTokenHint) {
    [query addParameter:kIdTokenHintKey value:_idTokenHint];
  }

  if (_postLogoutRedirectURL) {
    [query addParameter:kPostLogoutRedirectURLKey value:_postLogoutRedirectURL.absoluteString];
  }

  if (_state) {
    [query addParameter:kStateKey value:_state];
  }

  NSAssert(_configuration.endSessionEndpoint, OKTMissingEndSessionEndpointMessage);

  // Construct the URL
  return [query URLByReplacingQueryInURL:_configuration.endSessionEndpoint];
}

@end
