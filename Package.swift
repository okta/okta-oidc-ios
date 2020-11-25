// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OktaOidc",
    platforms: [
        .macOS(.v10_10),
        .iOS(.v11)
    ],
    products: [
        .library(name: "OktaOidc",
                 type: .dynamic,
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
                    ]),
        .testTarget(name: "OktaOidcTests",
                    dependencies: [
                        "OktaOidc_AppAuth",
                        "OktaOidc",
                        "TestCommon"
                    ])
    ]
)
