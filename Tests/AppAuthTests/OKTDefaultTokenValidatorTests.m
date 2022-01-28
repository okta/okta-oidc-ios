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

#import "OKTDefaultTokenValidatorTests.h"
#import "OKTDefaultTokenValidator.h"

@implementation OKTDefaultTokenValidatorTests

- (void)testDateExpiredValidation {
    id<OKTTokenValidator> validator = [OKTDefaultTokenValidator new];
    
    // Future
    XCTAssertFalse([validator isDateExpired:[NSDate dateWithTimeIntervalSinceNow:100]]);
    // Past
    XCTAssertTrue([validator isDateExpired:[NSDate dateWithTimeIntervalSinceNow:-100]]);
    // Nil
    XCTAssertFalse([validator isDateExpired:nil]);
}

- (void)testIssuedAtValidation {
    id<OKTTokenValidator> validator = [OKTDefaultTokenValidator new];
    
    // Past
    XCTAssertTrue([validator isIssuedAtDateValid:[NSDate dateWithTimeIntervalSinceNow:-100]]);
    // Now
    XCTAssertTrue([validator isIssuedAtDateValid:[NSDate dateWithTimeIntervalSinceNow:0]]);
    // Future
    XCTAssertTrue([validator isIssuedAtDateValid:[NSDate dateWithTimeIntervalSinceNow:100]]);
    // Max time
    XCTAssertFalse([validator isIssuedAtDateValid:[NSDate dateWithTimeIntervalSinceNow:kOKTAuthorizationSessionIATMaxSkew + 1]]);
}

@end
