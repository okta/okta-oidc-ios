/*! @file OKTAuthorizationService+Mac.m
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

#if TARGET_OS_OSX

#import "OKTAuthorizationService+Mac.h"

#import "OKTExternalUserAgentMac.h"

NS_ASSUME_NONNULL_BEGIN

@implementation OKTAuthorizationService (Mac)

+ (id<OKTExternalUserAgentSession>) presentAuthorizationRequest:(OKTAuthorizationRequest *)request
                                                       callback:(OKTAuthorizationCallback)callback {
  OKTExternalUserAgentMac *externalUserAgent = [[OKTExternalUserAgentMac alloc] init];
  return [self presentAuthorizationRequest:request
                         externalUserAgent:externalUserAgent
                                  callback:callback];
}

@end

NS_ASSUME_NONNULL_END

#endif
