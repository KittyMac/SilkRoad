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
        .package(url: "https://github.com/KittyMac/Jib.git", from: "0.0.2"),
        .package(url: "https://github.com/KittyMac/Pamphlet.git", from: "0.3.0"),
        .package(url: "https://github.com/KittyMac/Hitch.git", from: "0.4.0"),
        .package(url: "https://github.com/KittyMac/Spanker.git", from: "0.2.0"),
        .package(url: "https://github.com/KittyMac/Sextant.git", from: "0.4.0"),
        .package(url: "https://github.com/KittyMac/Flynn.git", branch: "master"),
    ],
    targets: [
        .target(
            name: "SilkRoadFramework",
            dependencies: [
                "Hitch",
                "Spanker",
                "Sextant",
                "Flynn",
                "Jib",
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
