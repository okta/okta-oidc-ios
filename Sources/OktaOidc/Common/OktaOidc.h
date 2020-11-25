/*
 * Copyright (c) 2017-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

#import "OKTAuthState.h"
#import "OKTAuthStateChangeDelegate.h"
#import "OKTAuthStateErrorDelegate.h"
#import "OKTAuthorizationRequest.h"
#import "OKTAuthorizationResponse.h"
#import "OKTAuthorizationService.h"
#import "OKTError.h"
#import "OKTErrorUtilities.h"
#import "OKTExternalUserAgent.h"
#import "OKTExternalUserAgentRequest.h"
#import "OKTExternalUserAgentSession.h"
#import "OKTGrantTypes.h"
#import "OKTIDToken.h"
#import "OKTRegistrationRequest.h"
#import "OKTRegistrationResponse.h"
#import "OKTResponseTypes.h"
#import "OKTScopes.h"
#import "OKTScopeUtilities.h"
#import "OKTServiceConfiguration.h"
#import "OKTServiceDiscovery.h"
#import "OKTTokenRequest.h"
#import "OKTTokenResponse.h"
#import "OKTTokenUtilities.h"
#import "OKTURLSessionProvider.h"
#import "OKTEndSessionRequest.h"
#import "OKTEndSessionResponse.h"
#import "OKTClientMetadataParameters.h"
#import "AppAuthCore.h"
#import "OKTDefines.h"
#import "OKTFieldMapping.h"
#import "OKTURLQueryComponent.h"
#import "OktaUserAgent.h"
#import "OktaNetworkRequestCustomizationDelegate.h"

#if TARGET_OS_IOS
#import "OKTAuthState+IOS.h"
#import "OKTAuthorizationService+IOS.h"
#import "OKTExternalUserAgentIOS.h"
#import "OKTExternalUserAgentNoSsoIOS.h"
#import "OKTExternalUserAgentIOSCustomBrowser.h"
#elif TARGET_OS_OSX
#import "OKTAuthState+Mac.h"
#import "OKTAuthorizationService+Mac.h"
#import "OKTExternalUserAgentMac.h"
#import "OKTRedirectHTTPHandler.h"
#import "OKTLoopbackHTTPServer.h"
#else
#error "Platform Undefined"
#endif
