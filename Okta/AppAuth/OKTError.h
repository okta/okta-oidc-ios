/*! @file OKTError.h
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

NS_ASSUME_NONNULL_BEGIN

/*! @brief The error domain for all NSErrors returned from the AppAuth library.
 */
extern NSString *const OKTGeneralErrorDomain;

/*! @brief The error domain for OAuth specific errors on the authorization endpoint.
    @discussion This error domain is used when the server responds to an authorization request
        with an explicit OAuth error, as defined by RFC6749 Section 4.1.2.1. If the authorization
        response is invalid and not explicitly an error response, another error domain will be used.
        The error response parameter dictionary is available in the
        \NSError_userInfo dictionary using the @c ::OKTOAuthErrorResponseErrorKey key.
        The \NSError_code will be one of the @c ::OKTErrorCodeOAuthAuthorization enum values.
    @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
 */
extern NSString *const OKTOAuthAuthorizationErrorDomain;

/*! @brief The error domain for OAuth specific errors on the token endpoint.
    @discussion This error domain is used when the server responds with HTTP 400 and an OAuth error,
        as defined RFC6749 Section 5.2. If an HTTP 400 response does not parse as an OAuth error
        (i.e. no 'error' field is present or the JSON is invalid), another error domain will be
        used. The entire OAuth error response dictionary is available in the \NSError_userInfo
        dictionary using the @c ::OKTOAuthErrorResponseErrorKey key. Unlike transient network
        errors, errors in this domain invalidate the authentication state, and either indicate a
        client error or require user interaction (i.e. reauthentication) to resolve.
        The \NSError_code will be one of the @c ::OKTErrorCodeOAuthToken enum values.
    @see https://tools.ietf.org/html/rfc6749#section-5.2
 */
extern NSString *const OKTOAuthTokenErrorDomain;

/*! @brief The error domain for dynamic client registration errors.
    @discussion This error domain is used when the server responds with HTTP 400 and an OAuth error,
         as defined in OpenID Connect Dynamic Client Registration 1.0 Section 3.3. If an HTTP 400
         response does not parse as an OAuth error (i.e. no 'error' field is present or the JSON is
         invalid), another error domain will be  used. The entire OAuth error response dictionary is
         available in the \NSError_userInfo dictionary using the @c ::OKTOAuthErrorResponseErrorKey
         key. Unlike transient network errors, errors in this domain invalidate the authentication
         state, and indicates a client error.
         The \NSError_code will be one of the @c ::OKTErrorCodeOAuthToken enum values.
     @see https://openid.net/specs/openid-connect-registration-1_0.html#RegistrationError
 */
extern NSString *const OKTOAuthRegistrationErrorDomain;

/*! @brief The error domain for authorization errors encountered out of band on the resource server.
 */
extern NSString *const OKTResourceServerAuthorizationErrorDomain;

/*! @brief An error domain representing received HTTP errors.
 */
extern NSString *const OKTHTTPErrorDomain;

/*! @brief An error key for the original OAuth error response (if any).
 */
extern NSString *const OKTOAuthErrorResponseErrorKey;

/*! @brief The key of the 'error' response field in a RFC6749 Section 5.2 response.
    @remark error
    @see https://tools.ietf.org/html/rfc6749#section-5.2
 */
extern NSString *const OKTOAuthErrorFieldError;

/*! @brief The key of the 'error_description' response field in a RFC6749 Section 5.2 response.
    @remark error_description
    @see https://tools.ietf.org/html/rfc6749#section-5.2
 */
extern NSString *const OKTOAuthErrorFieldErrorDescription;

/*! @brief The key of the 'error_uri' response field in a RFC6749 Section 5.2 response.
    @remark error_uri
    @see https://tools.ietf.org/html/rfc6749#section-5.2
 */
extern NSString *const OKTOAuthErrorFieldErrorURI;

/*! @brief The various error codes returned from the AppAuth library.
 */
typedef NS_ENUM(NSInteger, OKTErrorCode) {
  /*! @brief Indicates a problem parsing an OpenID Connect Service Discovery document.
   */
  OKTErrorCodeInvalidDiscoveryDocument = -2,

  /*! @brief Indicates the user manually canceled the OAuth authorization code flow.
   */
  OKTErrorCodeUserCanceledAuthorizationFlow = -3,

  /*! @brief Indicates an OAuth authorization flow was programmatically cancelled.
   */
  OKTErrorCodeProgramCanceledAuthorizationFlow = -4,

  /*! @brief Indicates a network error or server error occurred.
   */
  OKTErrorCodeNetworkError = -5,

  /*! @brief Indicates a server error occurred.
   */
  OKTErrorCodeServerError = -6,

  /*! @brief Indicates a problem occurred deserializing the response/JSON.
   */
  OKTErrorCodeJSONDeserializationError = -7,

  /*! @brief Indicates a problem occurred constructing the token response from the JSON.
   */
  OKTErrorCodeTokenResponseConstructionError = -8,

  /*! @brief @c UIApplication.openURL: returned NO when attempting to open the authorization
          request in mobile Safari.
   */
  OKTErrorCodeSafariOpenError = -9,

  /*! @brief @c NSWorkspace.openURL returned NO when attempting to open the authorization
          request in the default browser.
   */
  OKTErrorCodeBrowserOpenError = -10,

  /*! @brief Indicates a problem when trying to refresh the tokens.
   */
  OKTErrorCodeTokenRefreshError = -11,

  /*! @brief Indicates a problem occurred constructing the registration response from the JSON.
   */
  OKTErrorCodeRegistrationResponseConstructionError = -12,

  /*! @brief Indicates a problem occurred deserializing the response/JSON.
   */
  OKTErrorCodeJSONSerializationError = -13,

  /*! @brief The ID Token did not parse.
   */
  OKTErrorCodeIDTokenParsingError = -14,

  /*! @brief The ID Token did not pass validation (e.g. issuer, audience checks).
   */
  OKTErrorCodeIDTokenFailedValidationError = -15,
};

/*! @brief Enum of all possible OAuth error codes as defined by RFC6749
    @discussion Used by @c ::OKTErrorCodeOAuthAuthorization and @c ::OKTErrorCodeOAuthToken
        which define endpoint-specific subsets of OAuth codes. Those enum types are down-castable
        to this one.
    @see https://tools.ietf.org/html/rfc6749#section-11.4
    @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
    @see https://tools.ietf.org/html/rfc6749#section-5.2
 */
typedef NS_ENUM(NSInteger, OKTErrorCodeOAuth) {

  /*! @remarks invalid_request
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  OKTErrorCodeOAuthInvalidRequest = -2,

  /*! @remarks unauthorized_client
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  OKTErrorCodeOAuthUnauthorizedClient = -3,

  /*! @remarks access_denied
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
   */
  OKTErrorCodeOAuthAccessDenied = -4,

  /*! @remarks unsupported_response_type
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
   */
  OKTErrorCodeOAuthUnsupportedResponseType = -5,

  /*! @remarks invalid_scope
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  OKTErrorCodeOAuthInvalidScope = -6,

  /*! @remarks server_error
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
   */
  OKTErrorCodeOAuthServerError = -7,

  /*! @remarks temporarily_unavailable
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
   */
  OKTErrorCodeOAuthTemporarilyUnavailable = -8,

  /*! @remarks invalid_client
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  OKTErrorCodeOAuthInvalidClient = -9,

  /*! @remarks invalid_grant
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  OKTErrorCodeOAuthInvalidGrant = -10,

  /*! @remarks unsupported_grant_type
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  OKTErrorCodeOAuthUnsupportedGrantType = -11,

  /*! @remarks invalid_redirect_uri
      @see https://openid.net/specs/openid-connect-registration-1_0.html#RegistrationError
   */
  OKTErrorCodeOAuthInvalidRedirectURI = -12,

  /*! @remarks invalid_client_metadata
      @see https://openid.net/specs/openid-connect-registration-1_0.html#RegistrationError
   */
  OKTErrorCodeOAuthInvalidClientMetadata = -13,

  /*! @brief An authorization error occurring on the client rather than the server. For example,
        due to a state mismatch or misconfiguration. Should be treated as an unrecoverable
        authorization error.
   */
  OKTErrorCodeOAuthClientError = -0xEFFF,

  /*! @brief An OAuth error not known to this library
      @discussion Indicates an OAuth error as per RFC6749, but the error code was not in our
          list. It could be a custom error code, or one from an OAuth extension. See the "error" key
          of the \NSError_userInfo property. Such errors are assumed to invalidate the
          authentication state
   */
  OKTErrorCodeOAuthOther = -0xF000,
};

/*! @brief The error codes for the @c ::OKTOAuthAuthorizationErrorDomain error domain
    @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
 */
typedef NS_ENUM(NSInteger, OKTErrorCodeOAuthAuthorization) {
  /*! @remarks invalid_request
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
   */
  OKTErrorCodeOAuthAuthorizationInvalidRequest = OKTErrorCodeOAuthInvalidRequest,

  /*! @remarks unauthorized_client
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
   */
  OKTErrorCodeOAuthAuthorizationUnauthorizedClient = OKTErrorCodeOAuthUnauthorizedClient,

  /*! @remarks access_denied
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
   */
  OKTErrorCodeOAuthAuthorizationAccessDenied =
      OKTErrorCodeOAuthAccessDenied,

  /*! @remarks unsupported_response_type
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
   */
  OKTErrorCodeOAuthAuthorizationUnsupportedResponseType =
      OKTErrorCodeOAuthUnsupportedResponseType,

  /*! @brief Indicates a network error or server error occurred.
      @remarks invalid_scope
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
   */
  OKTErrorCodeOAuthAuthorizationAuthorizationInvalidScope = OKTErrorCodeOAuthInvalidScope,

  /*! @brief Indicates a server error occurred.
      @remarks server_error
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
   */
  OKTErrorCodeOAuthAuthorizationServerError = OKTErrorCodeOAuthServerError,

  /*! @remarks temporarily_unavailable
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
   */
  OKTErrorCodeOAuthAuthorizationTemporarilyUnavailable = OKTErrorCodeOAuthTemporarilyUnavailable,

  /*! @brief An authorization error occurring on the client rather than the server. For example,
        due to a state mismatch or client misconfiguration. Should be treated as an unrecoverable
        authorization error.
   */
  OKTErrorCodeOAuthAuthorizationClientError = OKTErrorCodeOAuthClientError,

  /*! @brief An authorization OAuth error not known to this library
      @discussion this indicates an OAuth error as per RFC6749, but the error code was not in our
          list. It could be a custom error code, or one from an OAuth extension. See the "error" key
          of the \NSError_userInfo property. We assume such errors are not transient.
      @see https://tools.ietf.org/html/rfc6749#section-4.1.2.1
   */
  OKTErrorCodeOAuthAuthorizationOther = OKTErrorCodeOAuthOther,
};


/*! @brief The error codes for the @c ::OKTOAuthTokenErrorDomain error domain
    @see https://tools.ietf.org/html/rfc6749#section-5.2
 */
typedef NS_ENUM(NSInteger, OKTErrorCodeOAuthToken) {
  /*! @remarks invalid_request
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  OKTErrorCodeOAuthTokenInvalidRequest = OKTErrorCodeOAuthInvalidRequest,

  /*! @remarks invalid_client
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  OKTErrorCodeOAuthTokenInvalidClient = OKTErrorCodeOAuthInvalidClient,

  /*! @remarks invalid_grant
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  OKTErrorCodeOAuthTokenInvalidGrant = OKTErrorCodeOAuthInvalidGrant,

  /*! @remarks unauthorized_client
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  OKTErrorCodeOAuthTokenUnauthorizedClient = OKTErrorCodeOAuthUnauthorizedClient,

  /*! @remarks unsupported_grant_type
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  OKTErrorCodeOAuthTokenUnsupportedGrantType = OKTErrorCodeOAuthUnsupportedGrantType,

  /*! @remarks invalid_scope
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  OKTErrorCodeOAuthTokenInvalidScope = OKTErrorCodeOAuthInvalidScope,

  /*! @brief An unrecoverable token error occurring on the client rather than the server.
   */
  OKTErrorCodeOAuthTokenClientError = OKTErrorCodeOAuthClientError,

  /*! @brief A token endpoint OAuth error not known to this library
      @discussion this indicates an OAuth error as per RFC6749, but the error code was not in our
          list. It could be a custom error code, or one from an OAuth extension. See the "error" key
          of the \NSError_userInfo property. We assume such errors are not transient.
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  OKTErrorCodeOAuthTokenOther = OKTErrorCodeOAuthOther,
};

/*! @brief The error codes for the @c ::OKTOAuthRegistrationErrorDomain error domain
    @see https://openid.net/specs/openid-connect-registration-1_0.html#RegistrationError
 */
typedef NS_ENUM(NSInteger, OKTErrorCodeOAuthRegistration) {
  /*! @remarks invalid_request
      @see http://tools.ietf.org/html/rfc6750#section-3.1
   */
  OKTErrorCodeOAuthRegistrationInvalidRequest = OKTErrorCodeOAuthInvalidRequest,

  /*! @remarks invalid_redirect_uri
      @see https://openid.net/specs/openid-connect-registration-1_0.html#RegistrationError
   */
  OKTErrorCodeOAuthRegistrationInvalidRedirectURI = OKTErrorCodeOAuthInvalidRedirectURI,

  /*! @remarks invalid_client_metadata
      @see https://openid.net/specs/openid-connect-registration-1_0.html#RegistrationError
   */
  OKTErrorCodeOAuthRegistrationInvalidClientMetadata = OKTErrorCodeOAuthInvalidClientMetadata,

  /*! @brief An unrecoverable token error occurring on the client rather than the server.
   */
  OKTErrorCodeOAuthRegistrationClientError = OKTErrorCodeOAuthClientError,

  /*! @brief A registration endpoint OAuth error not known to this library
      @discussion this indicates an OAuth error, but the error code was not in our
          list. It could be a custom error code, or one from an OAuth extension. See the "error" key
          of the \NSError_userInfo property. We assume such errors are not transient.
      @see https://tools.ietf.org/html/rfc6749#section-5.2
   */
  OKTErrorCodeOAuthRegistrationOther = OKTErrorCodeOAuthOther,
};


/*! @brief The exception text for the exception which occurs when a
        @c OKTExternalUserAgentSession receives a message after it has already completed.
 */
extern NSString *const OKTOAuthExceptionInvalidAuthorizationFlow;

/*! @brief The text for the exception which occurs when a Token Request is constructed
        with a null redirectURL for a grant_type that requires a nonnull Redirect
 */
extern NSString *const OKTOAuthExceptionInvalidTokenRequestNullRedirectURL;

NS_ASSUME_NONNULL_END
