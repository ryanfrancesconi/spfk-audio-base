// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// Swift target
private let name: String = "SPFKAudioBase"

private let platforms: [PackageDescription.SupportedPlatform]? = [
    .macOS(.v12)
]

private let products: [PackageDescription.Product] = [
    .library(
        name: name,
        targets: [name]
    )
]

private let dependencies: [PackageDescription.Package.Dependency] = [
    .package(name: "SPFKBase", path: "../SPFKBase"),
    .package(name: "SPFKTesting", path: "../SPFKTesting"),
    
//     .package(url: "https://github.com/ryanfrancesconi/SPFKUtils", branch: "main"),
//     .package(url: "https://github.com/ryanfrancesconi/SPFKTesting", branch: "main"),
]

private let targets: [PackageDescription.Target] = [
    // Swift
    .target(
        name: name,
        dependencies: [
            .byNameItem(name: "SPFKBase", condition: nil)
        ]
    ),
    

    .testTarget(
        name: "\(name)Tests",
        dependencies: [
            .byNameItem(name: name, condition: nil),
            .byNameItem(name: "SPFKTesting", condition: nil)
        ],
        resources: [
        ]
    )
]

let package = Package(
    name: name,
    defaultLocalization: "en",
    platforms: platforms,
    products: products,
    dependencies: dependencies,
    targets: targets,
    cxxLanguageStandard: .cxx20
)
