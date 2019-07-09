/*! @file OIDAuthorizationService+EndSession.h
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
#import "OIDAuthorizationService.h"

@class OIDEndSessionRequest;
@class OIDEndSessionResponse;

/*! @brief Block used as a callback for the end-session request of @c OIDAuthorizationService.
 @param endSessionResponse The end-session response, if available.
 @param error The error if an error occurred.
 */
typedef void (^OIDEndSessionCallback)(OIDEndSessionResponse *_Nullable endSessionResponse,
                                      NSError *_Nullable error);


NS_ASSUME_NONNULL_BEGIN

@interface OIDAuthorizationService(EndSession)

/*! @brief Perform a logout request.
 @param request The end-session logout request.
 @param externalUserAgent Generic external user-agent that can present user-agent requests.
 @param callback The method called when the request has completed or failed.
 @return A @c OIDExternalUserAgentSession instance which will terminate when it
 receives a @c OIDExternalUserAgentSession.cancel message, or after processing a
 @c OIDExternalUserAgentSession.resumeExternalUserAgentFlowWithURL: message.
 @see http://openid.net/specs/openid-connect-session-1_0.html#RPLogout
 */
+ (id<OIDExternalUserAgentSession>)
presentEndSessionRequest:(OIDEndSessionRequest *)request
externalUserAgent:(id<OIDExternalUserAgent>)externalUserAgent
callback:(OIDEndSessionCallback)callback;

@end

NS_ASSUME_NONNULL_END
