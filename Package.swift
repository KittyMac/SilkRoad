// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "SilkRoad",
    platforms: [
        .macOS(.v10_15), .iOS(.v11)
    ],
    products: [
        .library(name: "SilkRoadFramework", targets: ["SilkRoadFramework"]),
    ],
    dependencies: [
        .package(url: "https://github.com/KittyMac/Jib.git", from: "0.0.52"),
        .package(url: "https://github.com/KittyMac/Pamphlet.git", from: "0.3.62"),
        .package(url: "https://github.com/KittyMac/Hitch.git", from: "0.4.93"),
        .package(url: "https://github.com/KittyMac/Spanker.git", from: "0.2.30"),
        .package(url: "https://github.com/KittyMac/Sextant.git", from: "0.4.14"),
        .package(url: "https://github.com/KittyMac/Picaroon.git", from: "0.4.15"),
        .package(url: "https://github.com/KittyMac/Flynn.git", from: "0.4.31"),
    ],
    targets: [
        .executableTarget(
            name: "TestCLI"
        ),
        .target(
            name: "SilkRoadFramework",
            dependencies: [
                "Hitch",
                "Spanker",
                "Sextant",
                "Flynn",
                "Jib",
                "Picaroon",
                .product(name: "PamphletTool", package: "Pamphlet"),
            ],
            plugins: [
                .plugin(name: "PamphletReleaseOnlyPlugin", package: "Pamphlet"),
                .plugin(name: "FlynnPlugin", package: "Flynn")
            ]
        ),
        .testTarget(
            name: "SilkRoadTests",
            dependencies: ["SilkRoadFramework"]
        ),
    ]
)
