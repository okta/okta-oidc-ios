// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

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

import PackageDescription

let package = Package(
    name: "OktaOidc",
    platforms: [
        .macOS(.v10_14),
        .iOS(.v11)
    ],
    products: [
        .library(name: "OktaOidc",
                 targets: [
                    "OktaOidc",
                    "OktaOidc_AppAuth"
                 ])
    ],
    targets: [
        .target(name: "OktaOidc_AppAuth",
                path: "Sources/AppAuth",
                cSettings: [
                    .define("GCC_SYMBOLS_PRIVATE_EXTERN=NO", .when(platforms: [.iOS])),
                    .headerSearchPath("macOS/LoopbackHTTPServer", .when(platforms: [.macOS]))
                ]),
        .target(name: "OktaOidc",
                dependencies: [
                    "OktaOidc_AppAuth"
                ]),
    ] + [
        .target(name: "TestCommon",
                dependencies: [
                    "OktaOidc_AppAuth",
                    "OktaOidc"
                ],
                path: "Tests/Common"),
        .testTarget(name: "AppAuthTests",
                    dependencies: [
                        "OktaOidc_AppAuth",
                        "OktaOidc",
                        "TestCommon"
                    ],
                    exclude: [
                        "OKTRPProfileCode.m"
                    ]),
        .testTarget(name: "OktaOidcTests",
                    dependencies: [
                        "OktaOidc_AppAuth",
                        "OktaOidc",
                        "TestCommon"
                    ])
    ]
)
