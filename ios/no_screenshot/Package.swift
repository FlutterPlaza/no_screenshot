// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "no_screenshot",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "no-screenshot", targets: ["no_screenshot"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "no_screenshot",
            dependencies: [],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
