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

#import <Foundation/Foundation.h>

/*! @brief Allows to modify network requests and track responses in OktaOidc.
    @discussion More information could be found here: https://github.com/okta/okta-oidc-ios/blob/master/README.md#modify-network-requests.
 */
@protocol OktaNetworkRequestCustomizationDelegate <NSObject>

/*! @brief Makes necessary changes to the URLRequest object.
    @discussion Custom parameters could be added to the URLRequest here.
                Note: It is highly recommended to copy all of the existing parameters
                from the `request` object to modified request without any changes.
                Altering of this data could lead network request to fail.
    @param request The URLRequest object that could be changed.
    @return Customized URLRequest object.
*/
- (nullable NSURLRequest*)customizableURLRequest: (nullable NSURLRequest *)request;

/*! @brief Notifies about network request completion.
    @param response Response of the network request.
*/
- (void)didReceiveResponse: (nullable NSURLResponse *)response;

@end
