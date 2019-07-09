/*! @file OIDAuthorizationService+EndSession.m
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

#import "OIDAuthorizationService+EndSession.h"

#import "OIDEndSessionRequest.h"
#import "OIDEndSessionResponse.h"
#import "OIDAuthorizationRequest.h"
#import "OIDAuthorizationResponse.h"
#import "OIDDefines.h"
#import "OIDErrorUtilities.h"
#import "OIDExternalUserAgent.h"
#import "OIDExternalUserAgentSession.h"
#import "OIDIDToken.h"
#import "OIDRegistrationRequest.h"
#import "OIDRegistrationResponse.h"
#import "OIDServiceConfiguration.h"
#import "OIDServiceDiscovery.h"
#import "OIDTokenRequest.h"
#import "OIDTokenResponse.h"
#import "OIDURLQueryComponent.h"
#import "OIDURLSessionProvider.h"

@interface OIDEndSessionImplementation : NSObject<OIDExternalUserAgentSession> {
    // private variables
    OIDEndSessionRequest *_request;
    id<OIDExternalUserAgent> _externalUserAgent;
    OIDEndSessionCallback _pendingEndSessionCallback;
}
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithRequest:(OIDEndSessionRequest *)request
NS_DESIGNATED_INITIALIZER;
@end

@implementation OIDEndSessionImplementation

- (instancetype)initWithRequest:(OIDEndSessionRequest *)request {
    self = [super init];
    if (self) {
        _request = [request copy];
    }
    return self;
}

- (void)presentAuthorizationWithExternalUserAgent:(id<OIDExternalUserAgent>)externalUserAgent
                                         callback:(OIDEndSessionCallback)authorizationFlowCallback {
    _externalUserAgent = externalUserAgent;
    _pendingEndSessionCallback = authorizationFlowCallback;
    BOOL authorizationFlowStarted =
    [_externalUserAgent presentExternalUserAgentRequest:_request session:self];
    if (!authorizationFlowStarted) {
        NSError *safariError = [OIDErrorUtilities errorWithCode:OIDErrorCodeSafariOpenError
                                                underlyingError:nil
                                                    description:@"Unable to open Safari."];
        [self didFinishWithResponse:nil error:safariError];
    }
}

- (void)cancel {
    [_externalUserAgent dismissExternalUserAgentAnimated:YES completion:^{
        NSError *error = [OIDErrorUtilities
                          errorWithCode:OIDErrorCodeUserCanceledAuthorizationFlow
                          underlyingError:nil
                          description:nil];
        [self didFinishWithResponse:nil error:error];
    }];
}

/*! @brief Does the redirection URL equal another URL down to the path component?
 @param URL The first redirect URI to compare.
 @param redirectonURL The second redirect URI to compare.
 @return YES if the URLs match down to the path level (query params are ignored).
 */
+ (BOOL)URL:(NSURL *)URL matchesRedirectonURL:(NSURL *)redirectonURL {
    NSURL *standardizedURL = [URL standardizedURL];
    NSURL *standardizedRedirectURL = [redirectonURL standardizedURL];
    
    return OIDIsEqualIncludingNil(standardizedURL.scheme, standardizedRedirectURL.scheme)
    && OIDIsEqualIncludingNil(standardizedURL.user, standardizedRedirectURL.user)
    && OIDIsEqualIncludingNil(standardizedURL.password, standardizedRedirectURL.password)
    && OIDIsEqualIncludingNil(standardizedURL.host, standardizedRedirectURL.host)
    && OIDIsEqualIncludingNil(standardizedURL.port, standardizedRedirectURL.port)
    && OIDIsEqualIncludingNil(standardizedURL.path, standardizedRedirectURL.path);
}

- (BOOL)shouldHandleURL:(NSURL *)URL {
    // The logic of when to handle the URL is the same as for authorization requests: should match
    // down to the path component.
    return [[self class] URL:URL
        matchesRedirectonURL:_request.postLogoutRedirectURL];
}

- (BOOL)resumeExternalUserAgentFlowWithURL:(NSURL *)URL {
    // rejects URLs that don't match redirect (these may be completely unrelated to the authorization)
    if (![self shouldHandleURL:URL]) {
        return NO;
    }
    // checks for an invalid state
    if (!_pendingEndSessionCallback) {
        [NSException raise:OIDOAuthExceptionInvalidAuthorizationFlow
                    format:@"%@", OIDOAuthExceptionInvalidAuthorizationFlow, nil];
    }
    
    NSError *error;
    OIDEndSessionResponse *response = nil;
    
    OIDURLQueryComponent *query = [[OIDURLQueryComponent alloc] initWithURL:URL];
    response = [[OIDEndSessionResponse alloc] initWithRequest:_request
                                                   parameters:query.dictionaryValue];
    
    // verifies that the state in the response matches the state in the request, or both are nil
    if (!OIDIsEqualIncludingNil(_request.state, response.state)) {
        NSMutableDictionary *userInfo = [query.dictionaryValue mutableCopy];
        userInfo[NSLocalizedDescriptionKey] =
        [NSString stringWithFormat:@"State mismatch, expecting %@ but got %@ in authorization "
         "response %@",
         _request.state,
         response.state,
         response];
        response = nil;
        error = [NSError errorWithDomain:OIDOAuthAuthorizationErrorDomain
                                    code:OIDErrorCodeOAuthAuthorizationClientError
                                userInfo:userInfo];
    }
    
    [_externalUserAgent dismissExternalUserAgentAnimated:YES completion:^{
        [self didFinishWithResponse:response error:error];
    }];
    
    return YES;
}

- (void)failExternalUserAgentFlowWithError:(NSError *)error {
    [self didFinishWithResponse:nil error:error];
}

/*! @brief Invokes the pending callback and performs cleanup.
 @param response The authorization response, if any to return to the callback.
 @param error The error, if any, to return to the callback.
 */
- (void)didFinishWithResponse:(nullable OIDEndSessionResponse *)response
                        error:(nullable NSError *)error {
    OIDEndSessionCallback callback = _pendingEndSessionCallback;
    _pendingEndSessionCallback = nil;
    _externalUserAgent = nil;
    if (callback) {
        callback(response, error);
    }
}

@end

@implementation OIDAuthorizationService(EndSession)

+ (id<OIDExternalUserAgentSession>)
presentEndSessionRequest:(OIDEndSessionRequest *)request
externalUserAgent:(id<OIDExternalUserAgent>)externalUserAgent
callback:(OIDEndSessionCallback)callback {
    OIDEndSessionImplementation *flowSession =
    [[OIDEndSessionImplementation alloc] initWithRequest:request];
    [flowSession presentAuthorizationWithExternalUserAgent:externalUserAgent callback:callback];
    return flowSession;
}


@end
