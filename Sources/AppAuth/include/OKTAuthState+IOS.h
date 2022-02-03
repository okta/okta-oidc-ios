/*! @file OKTAuthState+IOS.h
    @brief AppAuth iOS SDK
    @copyright
        Copyright 2016 Google Inc. All Rights Reserved.
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

#if !TARGET_OS_OSX

#import <UIKit/UIKit.h>

#import "OKTAuthState.h"

NS_ASSUME_NONNULL_BEGIN

/*! @brief iOS specific convenience methods for @c OKTAuthState.
 */
@interface OKTAuthState (IOS)

/*! @brief Convenience method to create a @c OKTAuthState by presenting an authorization request
        and performing the authorization code exchange in the case of code flow requests. For
        the hybrid flow, the caller should validate the id_token and c_hash, then perform the token
        request (@c OKTAuthorizationService.performTokenRequest:callback:)
        and update the OKTAuthState with the results (@c
        OKTAuthState.updateWithTokenResponse:error:).
    @param authorizationRequest The authorization request to present.
    @param presentingViewController The view controller from which to present the
        @c SFSafariViewController. On iOS 13, the window of this UIViewController
        is used as the ASPresentationAnchor.
    @param delegate The network request customization delegate.
    @param callback The method called when the request has completed or failed.
    @return A @c OKTExternalUserAgentSession instance which will terminate when it
        receives a @c OKTExternalUserAgentSession.cancel message, or after processing a
        @c OKTExternalUserAgentSession.resumeExternalUserAgentFlowWithURL: message.
 */
+ (id<OKTExternalUserAgentSession>)
    authStateByPresentingAuthorizationRequest:(OKTAuthorizationRequest *)authorizationRequest
                     presentingViewController:(UIViewController *)presentingViewController
                                     delegate:(id<OktaNetworkRequestCustomizationDelegate> _Nullable)delegate
                                    validator:(id<OKTTokenValidator> _Nullable)validator
                                     callback:(OKTAuthStateAuthorizationCallback)callback;

+ (id<OKTExternalUserAgentSession>)
    authStateByPresentingAuthorizationRequest:(OKTAuthorizationRequest *)authorizationRequest
                                     delegate:(id<OktaNetworkRequestCustomizationDelegate> _Nullable)delegate
                                    validator:(id<OKTTokenValidator> _Nullable)validator
                                     callback:(OKTAuthStateAuthorizationCallback)callback API_AVAILABLE(ios(11))
    __deprecated_msg("This method will not work on iOS 13. Use "
        "authStateByPresentingAuthorizationRequest:presentingViewController:callback:");

@end

NS_ASSUME_NONNULL_END

#endif
