/*
 * Copyright (c) 2019, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

class OktaOidcTask<T> {
    let config: OktaOidcConfig
    let oktaAPI: OktaOidcHttpApiProtocol
 
    init(config: OktaOidcConfig, oktaAPI: OktaOidcHttpApiProtocol) {
        self.config = config
        self.oktaAPI = oktaAPI
    }
    
    // Schedules task for execution in background and invokes callback on completion.
    internal func run(callback: @escaping (T?, OktaOidcError?) -> Void) {
        // no op.
    }
}
