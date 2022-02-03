/*! @file OKTAuthState+IOS.m
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

#import "OKTAuthState+IOS.h"

#import "OKTExternalUserAgentIOS.h"

@implementation OKTAuthState (IOS)

+ (id<OKTExternalUserAgentSession>)
    authStateByPresentingAuthorizationRequest:(OKTAuthorizationRequest *)authorizationRequest
                     presentingViewController:(UIViewController *)presentingViewController
                                     delegate:(id<OktaNetworkRequestCustomizationDelegate> _Nullable)delegate
                                    validator:(id<OKTTokenValidator> _Nullable)validator
                                     callback:(OKTAuthStateAuthorizationCallback)callback {
    OKTExternalUserAgentIOS *externalUserAgent =
        [[OKTExternalUserAgentIOS alloc]
            initWithPresentingViewController:presentingViewController];
    return [self authStateByPresentingAuthorizationRequest:authorizationRequest
                                         externalUserAgent:externalUserAgent
                                                  delegate:delegate
                                                 validator: validator
                                                  callback:callback];
}

+ (id<OKTExternalUserAgentSession>)
    authStateByPresentingAuthorizationRequest:(OKTAuthorizationRequest *)authorizationRequest
                                     delegate:(id<OktaNetworkRequestCustomizationDelegate> _Nullable)delegate
                                    validator:(id<OKTTokenValidator> _Nullable)validator
                                     callback:(OKTAuthStateAuthorizationCallback)callback {
  OKTExternalUserAgentIOS *externalUserAgent = [[OKTExternalUserAgentIOS alloc] init];
  return [self authStateByPresentingAuthorizationRequest:authorizationRequest
                                       externalUserAgent:externalUserAgent
                                                delegate:delegate
                                               validator: validator
                                                callback:callback];
}

@end

#endif
