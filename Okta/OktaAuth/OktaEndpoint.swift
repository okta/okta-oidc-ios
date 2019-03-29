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

enum OktaEndpoint {
    case introspection
    case revocation
    case userInfo
    
    func getURL(discoveredMetadata: [String: Any]? = OktaAuth.discoveredMetadata,
                issuer: String? = OktaAuth.configuration?.issuer) -> URL? {
        if let discoveredEndpoint = discoveredMetadata?[discoveryMetadataKey] as? String {
            return URL(string: discoveredEndpoint)
        }
        
        guard let issuer = issuer else {
            return nil
        }

        if issuer.range(of: "oauth2") != nil {
            return URL(string: Utils.removeTrailingSlash(issuer) + "/v1/" + self.defaultPath)
        }

        return URL(string: Utils.removeTrailingSlash(issuer) + "/oauth2/v1/" + self.defaultPath)
    }
    
    var noEndpointError: OktaError {
        switch self {
        case .introspection:
            return OktaError.noIntrospectionEndpoint
        case .revocation:
            return OktaError.noRevocationEndpoint
        case .userInfo:
            return OktaError.noUserInfoEndpoint
        }
    }
    
    private var discoveryMetadataKey: String {
        switch self {
        case .introspection:
            return "introspection_endpoint"
        case .revocation:
            return "revocation_endpoint"
        case .userInfo:
            return "userinfo_endpoint"
        }
    }
    
    private var defaultPath: String {
        switch self {
        case .introspection:
            return "introspect"
        case .revocation:
            return "revoke"
        case .userInfo:
            return "userinfo"
        }
    }
}
