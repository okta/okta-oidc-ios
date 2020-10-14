/*! @file OKTScopesTests.m
    @brief AppAuth iOS SDK
    @copyright
        Copyright 2015 Google Inc. All Rights Reserved.
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

#import <XCTest/XCTest.h>

#import "OKTScopes.h"

// Ignore warnings about "Use of GNU statement expression extension" which is raised by our use of
// the XCTAssert___ macros.
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wgnu"

/*! @brief Unit tests for constants in @c OKTScopes.m.
    @remarks Arguably not worth tests for this file, but adding them for consistency, and so that
        any future enhancements have a place to add tests if need be.
 */
@interface OKTScopesTests : XCTestCase
@end
@implementation OKTScopesTests

- (void)testAddress {
  XCTAssertEqualObjects(OKTScopeAddress, @"address");
}

- (void)testEmail {
  XCTAssertEqualObjects(OKTScopeEmail, @"email");
}

- (void)testPhone {
  XCTAssertEqualObjects(OKTScopePhone, @"phone");
}

- (void)testProfile {
  XCTAssertEqualObjects(OKTScopeProfile, @"profile");
}

@end

#pragma GCC diagnostic pop
