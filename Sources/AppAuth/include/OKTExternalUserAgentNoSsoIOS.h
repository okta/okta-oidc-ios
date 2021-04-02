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

#import <UIKit/UIKit.h>
#import <AuthenticationServices/AuthenticationServices.h>

#import "OKTExternalUserAgent.h"

NS_ASSUME_NONNULL_BEGIN

/*! @brief An iOS specific external user-agent that uses the best possible user-agent available
           for the no-SSO sessions.
 */
@interface OKTExternalUserAgentNoSsoIOS : NSObject<OKTExternalUserAgent>

- (instancetype)init API_AVAILABLE(ios(11))
    __deprecated_msg("This method will not work on iOS 13, use "
                     "initWithPresentingViewController:presentingViewController");

/*! @brief The designated initializer.
    @param presentingViewController The view controller from which to present the
        \SFSafariViewController.
 */
- (instancetype)initWithPresentingViewController:
    (UIViewController *)presentingViewController
    NS_DESIGNATED_INITIALIZER;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
#pragma mark - ASWebAuthenticationPresentationContextProviding

- (ASPresentationAnchor)presentationAnchorForWebAuthenticationSession:(ASWebAuthenticationSession *)session API_AVAILABLE(ios(13.0));
#endif // __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000

NS_ASSUME_NONNULL_END

@end

#endif
