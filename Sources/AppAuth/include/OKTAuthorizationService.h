/*! @file OKTAuthorizationService.h
    @brief AppAuth iOS SDK
    @copyright
        Copyright 2015 Google Inc. All Rights Reserved.
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

#import <Foundation/Foundation.h>
#import "OktaNetworkRequestCustomizationDelegate.h"
#import "OKTTokenValidator.h"

@class OKTAuthorization;
@class OKTAuthorizationRequest;
@class OKTAuthorizationResponse;
@class OKTEndSessionRequest;
@class OKTEndSessionResponse;
@class OKTRegistrationRequest;
@class OKTRegistrationResponse;
@class OKTServiceConfiguration;
@class OKTTokenRequest;
@class OKTTokenResponse;
@protocol OKTExternalUserAgent;
@protocol OKTExternalUserAgentSession;

NS_ASSUME_NONNULL_BEGIN

/*! @brief Represents the type of block used as a callback for creating a service configuration from
        a remote OpenID Connect Discovery document.
    @param configuration The service configuration, if available.
    @param error The error if an error occurred.
 */
typedef void (^OKTDiscoveryCallback)(OKTServiceConfiguration *_Nullable configuration,
                                     NSError *_Nullable error);

/*! @brief Represents the type of block used as a callback for various methods of
        @c OKTAuthorizationService.
    @param authorizationResponse The authorization response, if available.
    @param error The error if an error occurred.
 */
typedef void (^OKTAuthorizationCallback)(OKTAuthorizationResponse *_Nullable authorizationResponse,
                                         NSError *_Nullable error);

/*! @brief Block used as a callback for the end-session request of @c OKTAuthorizationService.
    @param endSessionResponse The end-session response, if available.
    @param error The error if an error occurred.
 */
typedef void (^OKTEndSessionCallback)(OKTEndSessionResponse *_Nullable endSessionResponse,
                                      NSError *_Nullable error);

/*! @brief Represents the type of block used as a callback for various methods of
        @c OKTAuthorizationService.
    @param tokenResponse The token response, if available.
    @param error The error if an error occurred.
 */
typedef void (^OKTTokenCallback)(OKTTokenResponse *_Nullable tokenResponse,
                                 NSError *_Nullable error);

/*! @brief Represents the type of dictionary used to specify additional querystring parameters
        when making authorization or token endpoint requests.
 */
typedef NSDictionary<NSString *, NSString *> *_Nullable OKTTokenEndpointParameters;

/*! @brief Represents the type of block used as a callback for various methods of
        @c OKTAuthorizationService.
    @param registrationResponse The registration response, if available.
    @param error The error if an error occurred.
*/
typedef void (^OKTRegistrationCompletion)(OKTRegistrationResponse *_Nullable registrationResponse,
                                          NSError *_Nullable error);

/*! @brief Performs various OAuth and OpenID Connect related calls via the user agent or
        \NSURLSession.
 */
@interface OKTAuthorizationService : NSObject

/*! @brief The service's configuration.
    @remarks Each authorization service is initialized with a configuration. This configuration
        specifies how to connect to a particular OAuth provider. Clients should use separate
        authorization service instances for each provider they wish to integrate with.
        Configurations may be created manually, or via an OpenID Connect Discovery Document.
 */
@property(nonatomic, readonly) OKTServiceConfiguration *configuration;

/*! @internal
    @brief Unavailable. This class should not be initialized.
 */
- (instancetype)init NS_UNAVAILABLE;

/*! @brief Convenience method for creating an authorization service configuration from an OpenID
        Connect compliant issuer URL.
    @param issuerURL The service provider's OpenID Connect issuer.
    @param completion A block which will be invoked when the authorization service configuration has
        been created, or when an error has occurred.
    @see https://openid.net/specs/openid-connect-discovery-1_0.html
 */
+ (void)discoverServiceConfigurationForIssuer:(NSURL *)issuerURL
                                   completion:(OKTDiscoveryCallback)completion;


/*! @brief Convenience method for creating an authorization service configuration from an OpenID
        Connect compliant identity provider's discovery document.
    @param discoveryURL The URL of the service provider's OpenID Connect discovery document.
    @param completion A block which will be invoked when the authorization service configuration has
        been created, or when an error has occurred.
    @see https://openid.net/specs/openid-connect-discovery-1_0.html
 */
+ (void)discoverServiceConfigurationForDiscoveryURL:(NSURL *)discoveryURL
                                         completion:(OKTDiscoveryCallback)completion;

/*! @brief Perform an authorization flow using a generic flow shim.
    @param request The authorization request.
    @param externalUserAgent Generic external user-agent that can present an authorization
        request.
    @param callback The method called when the request has completed or failed.
    @return A @c OKTExternalUserAgentSession instance which will terminate when it
        receives a @c OKTExternalUserAgentSession.cancel message, or after processing a
        @c OKTExternalUserAgentSession.resumeExternalUserAgentFlowWithURL: message.
 */
+ (id<OKTExternalUserAgentSession>) presentAuthorizationRequest:(OKTAuthorizationRequest *)request
    externalUserAgent:(id<OKTExternalUserAgent>)externalUserAgent
             callback:(OKTAuthorizationCallback)callback;

/*! @brief Perform a logout request.
    @param request The end-session logout request.
    @param externalUserAgent Generic external user-agent that can present user-agent requests.
    @param callback The method called when the request has completed or failed.
    @return A @c OKTExternalUserAgentSession instance which will terminate when it
        receives a @c OKTExternalUserAgentSession.cancel message, or after processing a
        @c OKTExternalUserAgentSession.resumeExternalUserAgentFlowWithURL: message.
    @see http://openid.net/specs/openid-connect-session-1_0.html#RPLogout
 */
+ (id<OKTExternalUserAgentSession>)
    presentEndSessionRequest:(OKTEndSessionRequest *)request
           externalUserAgent:(id<OKTExternalUserAgent>)externalUserAgent
                    callback:(OKTEndSessionCallback)callback;

/*! @brief Performs a token request.
    @param request The token request.
    @param delegate The network request customization delegate.
    @param callback The method called when the request has completed or failed.
 */
+ (void)performTokenRequest:(OKTTokenRequest *)request
                   delegate:(id<OktaNetworkRequestCustomizationDelegate> _Nullable)delegate
                   callback:(OKTTokenCallback)callback;

/*! @brief Performs a token request.
    @param request The token request.
    @param authorizationResponse The original authorization response related to this token request.
    @param delegate The network request customization delegate.
    @param validator Validates token.
    @param callback The method called when the request has completed or failed.
 */
+ (void)performTokenRequest:(OKTTokenRequest *)request
originalAuthorizationResponse:(OKTAuthorizationResponse *_Nullable)authorizationResponse
                   delegate:(id<OktaNetworkRequestCustomizationDelegate> _Nullable)delegate
                  validator:(id<OKTTokenValidator> _Nonnull)validator
                   callback:(OKTTokenCallback)callback;

/*! @brief Performs a registration request.
    @param request The registration request.
    @param delegate The network request customization delegate.
    @param completion The method called when the request has completed or failed.
 */
+ (void)performRegistrationRequest:(OKTRegistrationRequest *)request
                          delegate:(id<OktaNetworkRequestCustomizationDelegate> _Nullable)delegate
                        completion:(OKTRegistrationCompletion)completion;

@end

NS_ASSUME_NONNULL_END
