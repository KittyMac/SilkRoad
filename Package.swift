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
        .package(url: "https://github.com/KittyMac/Hitch.git", from: "0.4.0"),
        .package(url: "https://github.com/KittyMac/Spanker.git", from: "0.2.0"),
    ],
    targets: [
        .target(
            name: "SilkRoadFramework",
            dependencies: [
                "Hitch",
                "Spanker"
            ]
        ),
        .testTarget(
            name: "SilkRoadTests",
            dependencies: ["SilkRoadFramework"]
        ),
    ]
)
