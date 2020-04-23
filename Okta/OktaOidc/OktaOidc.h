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

#import "OIDAuthState.h"
#import "OIDAuthStateChangeDelegate.h"
#import "OIDAuthStateErrorDelegate.h"
#import "OIDAuthorizationRequest.h"
#import "OIDAuthorizationResponse.h"
#import "OIDAuthorizationService.h"
#import "OIDError.h"
#import "OIDErrorUtilities.h"
#import "OIDExternalUserAgent.h"
#import "OIDExternalUserAgentRequest.h"
#import "OIDExternalUserAgentSession.h"
#import "OIDGrantTypes.h"
#import "OIDIDToken.h"
#import "OIDRegistrationRequest.h"
#import "OIDRegistrationResponse.h"
#import "OIDResponseTypes.h"
#import "OIDScopes.h"
#import "OIDScopeUtilities.h"
#import "OIDServiceConfiguration.h"
#import "OIDServiceDiscovery.h"
#import "OIDTokenRequest.h"
#import "OIDTokenResponse.h"
#import "OIDTokenUtilities.h"
#import "OIDURLSessionProvider.h"
#import "OIDEndSessionRequest.h"
#import "OIDEndSessionResponse.h"
#import "OIDClientMetadataParameters.h"
#import "AppAuthCore.h"
#import "OIDDefines.h"
#import "OIDFieldMapping.h"
#import "OIDURLQueryComponent.h"
#import "OktaUserAgent.h"

#if TARGET_OS_IOS
#import "OIDAuthState+IOS.h"
#import "OIDAuthorizationService+IOS.h"
#import "OIDExternalUserAgentIOS.h"
#import "OIDExternalUserAgentIOSCustomBrowser.h"
#elif TARGET_OS_MAC
#import "OIDAuthState+Mac.h"
#import "OIDAuthorizationService+Mac.h"
#import "OIDExternalUserAgentMac.h"
#import "OIDRedirectHTTPHandler.h"
#import "OIDLoopbackHTTPServer.h"
#else
#error "Platform Undefined"
#endif
