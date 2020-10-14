/*! @file OKTError.m
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

#import "OKTError.h"

NSString *const OKTGeneralErrorDomain = @"org.openid.appauth.general";

NSString *const OKTOAuthTokenErrorDomain = @"org.openid.appauth.oauth_token";

NSString *const OKTOAuthAuthorizationErrorDomain = @"org.openid.appauth.oauth_authorization";

NSString *const OKTOAuthRegistrationErrorDomain = @"org.openid.appauth.oauth_registration";

NSString *const OKTResourceServerAuthorizationErrorDomain = @"org.openid.appauth.resourceserver";

NSString *const OKTHTTPErrorDomain = @"org.openid.appauth.remote-http";

NSString *const OKTOAuthExceptionInvalidAuthorizationFlow = @"An OAuth redirect was sent to a "
    "OKTExternalUserAgentSession after it already completed.";

NSString *const OKTOAuthExceptionInvalidTokenRequestNullRedirectURL = @"A OKTTokenRequest was "
    "created with a grant_type that requires a redirectURL, but a null redirectURL was given";

NSString *const OKTOAuthErrorResponseErrorKey = @"OKTOAuthErrorResponseErrorKey";

NSString *const OKTOAuthErrorFieldError = @"error";

NSString *const OKTOAuthErrorFieldErrorDescription = @"error_description";

NSString *const OKTOAuthErrorFieldErrorURI = @"error_uri";
