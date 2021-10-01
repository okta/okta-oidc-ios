/*
 * Copyright (c) 2020-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

#import <Foundation/Foundation.h>

#if !TARGET_OS_OSX

#import "OKTExternalUserAgentNoSsoIOS.h"

#import <SafariServices/SafariServices.h>
#import <AuthenticationServices/AuthenticationServices.h>

#import "OKTErrorUtilities.h"
#import "OKTExternalUserAgentSession.h"
#import "OKTExternalUserAgentRequest.h"

NS_ASSUME_NONNULL_BEGIN

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
@interface OKTExternalUserAgentNoSsoIOS ()<SFSafariViewControllerDelegate, ASWebAuthenticationPresentationContextProviding>
@end
#else
@interface OKTExternalUserAgentNoSsoIOS ()<SFSafariViewControllerDelegate>
@end
#endif

@implementation OKTExternalUserAgentNoSsoIOS {
  UIViewController *_presentingViewController;

  BOOL _externalUserAgentFlowInProgress;
  __weak id<OKTExternalUserAgentSession> _session;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
  ASWebAuthenticationSession *_webAuthenticationVC;
#pragma clang diagnostic pop
}

- (nonnull instancetype)init {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
  return [self initWithPresentingViewController:nil];
#pragma clang diagnostic pop
}

- (nonnull instancetype)initWithPresentingViewController:
    (UIViewController *)presentingViewController {
  self = [super init];
  if (self) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    NSAssert(presentingViewController != nil,
             @"presentingViewController cannot be nil on iOS 13");
#endif // __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    
    _presentingViewController = presentingViewController;
  }
  return self;
}

- (BOOL)presentExternalUserAgentRequest:(id<OKTExternalUserAgentRequest>)request
                                session:(id<OKTExternalUserAgentSession>)session {
  if (_externalUserAgentFlowInProgress) {
    // TODO: Handle errors as authorization is already in progress.
    return NO;
  }

  _externalUserAgentFlowInProgress = YES;
  _session = session;
  BOOL openedUserAgent = NO;
  NSURL *requestURL = [request externalUserAgentRequestURL];

  // iOS 13 and later, use ASWebAuthenticationSession
  if (@available(iOS 13.0, *)) {
    // ASWebAuthenticationSession doesn't work with guided access (rdar://40809553)
    if (!UIAccessibilityIsGuidedAccessEnabled()) {
      __weak OKTExternalUserAgentNoSsoIOS *weakSelf = self;
      NSString *redirectScheme = request.redirectScheme;
      ASWebAuthenticationSession *authenticationVC =
          [[ASWebAuthenticationSession alloc] initWithURL:requestURL
                                        callbackURLScheme:redirectScheme
                                         completionHandler:^(NSURL * _Nullable callbackURL,
                                                             NSError * _Nullable error) {
        __strong OKTExternalUserAgentNoSsoIOS *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        strongSelf->_webAuthenticationVC = nil;
        if (callbackURL) {
          [strongSelf->_session resumeExternalUserAgentFlowWithURL:callbackURL];
        } else {
          NSError *safariError =
              [OKTErrorUtilities errorWithCode:OKTErrorCodeUserCanceledAuthorizationFlow
                               underlyingError:error
                                   description:nil];
          [strongSelf->_session failExternalUserAgentFlowWithError:safariError];
        }
      }];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
      authenticationVC.presentationContextProvider = self;
      authenticationVC.prefersEphemeralWebBrowserSession = YES;
#endif
      _webAuthenticationVC = authenticationVC;
      openedUserAgent = [authenticationVC start];
    }
  }

  if (!openedUserAgent) {
    [self cleanUp];
    NSError *safariError = [OKTErrorUtilities errorWithCode:OKTErrorCodeSafariOpenError
                                            underlyingError:nil
                                                description:@"Unable to open user agent."];
    [session failExternalUserAgentFlowWithError:safariError];
  }
  return openedUserAgent;
}

- (void)dismissExternalUserAgentAnimated:(BOOL)animated completion:(void (^)(void))completion {
  if (!_externalUserAgentFlowInProgress) {
    // Ignore this call if there is no authorization flow in progress.
    if (completion) completion();
    return;
  }
  
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
  ASWebAuthenticationSession *webAuthenticationVC = _webAuthenticationVC;
#pragma clang diagnostic pop
  
  [self cleanUp];
  
  if (webAuthenticationVC) {
    // dismiss the ASWebAuthenticationSession
    [webAuthenticationVC cancel];
    if (completion) completion();
  } else {
    if (completion) completion();
  }
}

- (void)cleanUp {
  // The weak references to |_safariVC| and |_session| are set to nil to avoid accidentally using
  // them while not in an authorization flow.
  _session = nil;
  _externalUserAgentFlowInProgress = NO;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
#pragma mark - ASWebAuthenticationPresentationContextProviding

- (ASPresentationAnchor)presentationAnchorForWebAuthenticationSession:(ASWebAuthenticationSession *)session API_AVAILABLE(ios(13.0)){
  return _presentingViewController.view.window;
}
#endif // __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000

@end

NS_ASSUME_NONNULL_END

#endif
