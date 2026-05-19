// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HanToggle",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "HanToggle",
            targets: ["HanToggle"]
        ),
        .executable(
            name: "hantoggle",
            targets: ["HanToggleCLI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ddddxxx/SwiftyOpenCC.git", exact: "2.0.0-beta"),
    ],
    targets: [
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "HanToggle",
            dependencies: [
                .product(name: "OpenCC", package: "SwiftyOpenCC"),
            ]
        ),
        .executableTarget(
            name: "HanToggleCLI",
            dependencies: ["HanToggle"]
        ),
        .testTarget(
            name: "HanToggleTests",
            dependencies: ["HanToggle"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
