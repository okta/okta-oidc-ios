// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OktaOidc",
    platforms: [
        .iOS(.v11),
//        .macOS(.v10_10),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "okta-oidc",
            targets: ["OktaOidc"]
        ),
//        .library(
//            name: "okta-oidc-mac",
//            targets: ["OktaOidc-macOS"]
//        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "OktaOidc",
            dependencies: ["AppAuth"],
            path: "Okta/OktaOidc",
            exclude: [
                "iOS",
                "Internal/iOS",
                "Internal/Tasks/iOS",
                "macOS",
                "Internal/macOS",
                "Internal/Tasks/macOS",
            ]
        ),

        .target(
            name: "AppAuth",
            dependencies: [],
            path: "Okta/AppAuth",
            exclude: [
                "iOS",
                "macOS",
            ],
            cSettings: [
                .headerSearchPath("Internal"),
//                .define("BUILD_FOR_IOS")
            ]
        ),

//        .target(
//            name: "OktaOidc-macOS",
//            dependencies: ["AppAuth-macOS"],
//            path: "Okta/OktaOidc",
//            exclude: [
//                "iOS",
//                "Internal/iOS",
//                "Internal/Tasks/iOS",
//            ]
//        ),
//
//        .target(
//            name: "AppAuth-macOS",
//            dependencies: [],
//            path: "Okta/AppAuth",
//            exclude: [
//                "iOS",
//            ],
//            cSettings: [
//                .headerSearchPath("Internal"),
//            ]
//        ),
    ],
    swiftLanguageVersions: [.v5]
)
