/*
 * Copyright (c) 2022-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

#import "OKTDefaultTokenValidator.h"

int const kOKTAuthorizationSessionIATMaxSkew = 600;

@implementation OKTDefaultTokenValidator

- (BOOL)isDateExpired:(nullable NSDate *)expiresAtDate token:(OKTTokenType)tokenType {
    if (!expiresAtDate) {
        return YES;
    }
    
    switch (tokenType) {
        case OKTTokenTypeId: {
            // OpenID Connect Core Section 3.1.3.7. rule #9
            // Validates that the current time is before the expiry time.
            NSTimeInterval expiresAtDifference = [expiresAtDate timeIntervalSinceNow];
            return expiresAtDifference < 0;
        }
        case OKTTokenTypeAccess:
            return expiresAtDate.timeIntervalSince1970 <= [NSDate new].timeIntervalSince1970;
        default:
            NSAssert(NO, @"Unknown token type.");
            return YES;
    }
}

- (BOOL)isIssuedAtDateValid:(nullable NSDate *)issuedAt token:(OKTTokenType)tokenType {
    if (!issuedAt) {
        return NO;
    }
    
    // OpenID Connect Core Section 3.1.3.7. rule #10
    // Validates that the issued at time is not more than +/- 10 minutes on the current time.
    NSTimeInterval issuedAtDifference = [issuedAt timeIntervalSinceNow];
    return fabs(issuedAtDifference) <= kOKTAuthorizationSessionIATMaxSkew;
}

@end
