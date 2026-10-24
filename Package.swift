// swift-tools-version: 6.2
// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi

import PackageDescription

let package = Package(
    name: "spfk-audio-base",
    defaultLocalization: "en",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(
            name: "SPFKAudioBase",
            targets: ["SPFKAudioBase"]
        ),
        .library(
            name: "SPFKAudioBaseC",
            targets: ["SPFKAudioBaseC"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ryanfrancesconi/spfk-base", from: "1.2.2"),
        .package(url: "https://github.com/ryanfrancesconi/spfk-filesystem", from: "1.9.0"),
        .package(url: "https://github.com/ryanfrancesconi/spfk-testing", from: "1.1.0"),
    ],
    targets: [
        .target(
            name: "SPFKAudioBase",
            dependencies: [
                .product(name: "SPFKBase", package: "spfk-base"),
                .product(name: "SPFKFileSystem", package: "spfk-filesystem"),
                .targetItem(name: "SPFKAudioBaseC", condition: nil),
            ],
            resources: [.process("Resources")]
        ),
        .target(
            name: "SPFKAudioBaseC",
            dependencies: [],
            publicHeadersPath: "include"
        ),
        .testTarget(
            name: "SPFKAudioBaseTests",
            dependencies: [
                .targetItem(name: "SPFKAudioBase", condition: nil),
                .targetItem(name: "SPFKAudioBaseC", condition: nil),
                .product(name: "SPFKBase", package: "spfk-base"),
                .product(name: "SPFKTesting", package: "spfk-testing"),
            ]
        ),
    ]
)
