/*! @file OKTRedirectHTTPHandler.m
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

#import "OKTRedirectHTTPHandler.h"

#if TARGET_OS_OSX

#import "OKTAuthorizationService.h"
#import "OKTErrorUtilities.h"
#import "OKTExternalUserAgentSession.h"
#import "OKTLoopbackHTTPServer.h"

/*! @brief Page that is returned following a completed authorization. Show your own page instead by
        supplying a URL in @c initWithSuccessURL that the user will be redirected to.
 */
static NSString *const kHTMLAuthorizationComplete =
    @"<html><body>Authorization complete.<br> Return to the app.</body></html>";

/*! @brief Error warning that the @c currentAuthorizationFlow is not set on this object (likely a
        developer error, unless the user stumbled upon the loopback server before the authorization
        had started completely).
    @description An object conforming to @c OKTExternalUserAgentSession is returned when the
        authorization is presented with
        @c OKTAuthorizationService::presentAuthorizationRequest:callback:. It should be set to
        @c currentAuthorization when using a loopback redirect.
 */
static NSString *const kHTMLErrorMissingCurrentAuthorizationFlow =
    @"<html><body>AppAuth Error: No <code>currentAuthorizationFlow</code> is set on the "
     "<code>OKTRedirectHTTPHandler</code>. Cannot process redirect.</body></html>";

/*! @brief Error warning that the URL does not represent a valid redirect. This should be rare, may
        happen if the user stumbles upon the loopback server randomly.
 */
static NSString *const kHTMLErrorRedirectNotValid =
    @"<html><body>AppAuth Error: Not a valid redirect.</body></html>";

@implementation OKTRedirectHTTPHandler {
  HTTPServer *_httpServ;
  NSURL *_successURL;
}

- (instancetype)init {
  return [self initWithSuccessURL:nil];
}

- (instancetype)initWithSuccessURL:(nullable NSURL *)successURL {
  self = [super init];
  if (self) {
    _successURL = [successURL copy];
  }
  return self;
}

- (NSURL *)startHTTPListener:(NSString *)domain withPort:(uint16_t)port error:(NSError **)returnError  {
  // Cancels any pending requests.
  [self cancelHTTPListener];

  // Starts a HTTP server on the loopback interface.
  // By not specifying a port, a random available one will be assigned.
  _httpServ = [[HTTPServer alloc] init];
  [_httpServ setPort:port];
  [_httpServ setDelegate:self];
  NSError *error = nil;
  if (![_httpServ start:&error]) {
    if (returnError) {
      *returnError = error;
    }
    return nil;
  } else if (domain.length > 0) {
      // Use provided domain name
      NSString *serverURL = [NSString stringWithFormat:@"http://%@:%d/", domain, [_httpServ port]];
      return [NSURL URLWithString:serverURL];
  } else if ([_httpServ hasIPv4Socket]) {
    // Prefer the IPv4 loopback address
    NSString *serverURL = [NSString stringWithFormat:@"http://127.0.0.1:%d/", [_httpServ port]];
    return [NSURL URLWithString:serverURL];
  } else if ([_httpServ hasIPv6Socket]) {
    // Use the IPv6 loopback address if IPv4 isn't available
    NSString *serverURL = [NSString stringWithFormat:@"http://[::1]:%d/", [_httpServ port]];
    return [NSURL URLWithString:serverURL];
  }

  return nil;
}

- (NSURL *)startHTTPListener:(NSString *)domain error:(NSError **)returnError {
  // A port of 0 requests a random available port
  return [self startHTTPListener:domain withPort:63875 error:returnError];
}

- (void)cancelHTTPListener {
  [self stopHTTPListener];

  // Cancels the pending authorization flow (if any) with error.
  NSError *cancelledError =
      [OKTErrorUtilities errorWithCode:OKTErrorCodeProgramCanceledAuthorizationFlow
                       underlyingError:nil
                           description:@"The HTTP listener was cancelled programmatically."];
  [_currentAuthorizationFlow failExternalUserAgentFlowWithError:cancelledError];
  _currentAuthorizationFlow = nil;
}

/*! @brief Stops listening on the loopback interface without modifying the state of the
        @c currentAuthorizationFlow. Should be called when the authorization flow completes or is
        cancelled.
 */
- (void)stopHTTPListener {
  _httpServ.delegate = nil;
  [_httpServ stop];
  _httpServ = nil;
}

- (BOOL)isOptionsHTTPServerRequest:(HTTPServerRequest *)request {
    CFStringRef method = CFHTTPMessageCopyRequestMethod(request.request);
    if (method == nil) {
        return NO;
    }

    BOOL isOptionsRequest = CFStringCompare(method, (__bridge CFStringRef)@"OPTIONS", kCFCompareCaseInsensitive) == kCFCompareEqualTo;
    CFRelease(method);

    return isOptionsRequest;
}

- (void)HTTPConnection:(HTTPConnection *)conn didReceiveRequest:(HTTPServerRequest *)mess {
  // Handle private network preflight
  // https://developer.chrome.com/blog/private-network-access-preflight/
  BOOL isOptionsRequest = [self isOptionsHTTPServerRequest:mess];

  CFStringRef requestPrivateNetwork = isOptionsRequest ? CFHTTPMessageCopyHeaderFieldValue(mess.request, (__bridge CFStringRef)@"Access-Control-Request-Private-Network") : nil;
  BOOL doesRequestPrivateNetwork = requestPrivateNetwork != nil && CFStringCompare(requestPrivateNetwork, (__bridge CFStringRef)@"true", 0) == kCFCompareEqualTo;
  if (requestPrivateNetwork != nil) {
    CFRelease(requestPrivateNetwork);
  }
  if (isOptionsRequest && doesRequestPrivateNetwork) {
    CFHTTPMessageRef response = CFHTTPMessageCreateResponse(
                                                            kCFAllocatorDefault,
                                                            200,
                                                            NULL,
                                                            kCFHTTPVersion1_1);
    CFStringRef origin = CFHTTPMessageCopyHeaderFieldValue(mess.request, (__bridge CFStringRef)@"Origin");
    CFHTTPMessageSetHeaderFieldValue(response,
                                     (__bridge CFStringRef)@"Access-Control-Allow-Origin",
                                     origin);
    CFHTTPMessageSetHeaderFieldValue(response,
                                     (__bridge CFStringRef)@"Access-Control-Allow-Credentials",
                                     (__bridge CFStringRef)@"true");
    CFHTTPMessageSetHeaderFieldValue(response,
                                     (__bridge CFStringRef)@"Access-Control-Allow-Private-Network",
                                     (__bridge CFStringRef)@"true");
    CFHTTPMessageSetHeaderFieldValue(response,
                                     (__bridge CFStringRef)@"Content-Length",
                                     (__bridge CFStringRef)@"0");
    [mess setResponse:response];
    CFRelease(response);
    return;
  }

  BOOL handled = NO;
  // Sends URL to AppAuth.
  CFURLRef url = CFHTTPMessageCopyRequestURL(mess.request);
  if (url != nil) {
    handled = [_currentAuthorizationFlow resumeExternalUserAgentFlowWithURL:(__bridge NSURL *)url];
    CFRelease(url);
  }

  // Stops listening to further requests after the first valid authorization response.
  if (handled) {
    _currentAuthorizationFlow = nil;
    [self stopHTTPListener];
  }

  // Responds to browser request.
  NSString *bodyText = kHTMLAuthorizationComplete;
  NSInteger httpResponseCode = (_successURL) ? 302 : 200;
  // Returns an error page if a URL other than the expected redirect is requested.
  if (!handled) {
    if (_currentAuthorizationFlow) {
      bodyText = kHTMLErrorRedirectNotValid;
      httpResponseCode = 404;
    } else {
      bodyText = kHTMLErrorMissingCurrentAuthorizationFlow;
      httpResponseCode = 400;
    }
  }
  NSData *data = [bodyText dataUsingEncoding:NSUTF8StringEncoding];

  CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault,
                                                          httpResponseCode,
                                                          NULL,
                                                          kCFHTTPVersion1_1);
  if (httpResponseCode == 302) {
    CFHTTPMessageSetHeaderFieldValue(response,
                                     (__bridge CFStringRef)@"Location",
                                     (__bridge CFStringRef)_successURL.absoluteString);
  }
  CFHTTPMessageSetHeaderFieldValue(response,
                                   (__bridge CFStringRef)@"Content-Length",
                                   (__bridge CFStringRef)[NSString stringWithFormat:@"%lu",
                                       (unsigned long)data.length]);
  CFHTTPMessageSetBody(response, (__bridge CFDataRef)data);

  [mess setResponse:response];
  CFRelease(response);
}

- (void)dealloc {
  [self cancelHTTPListener];
}

@end

#endif
