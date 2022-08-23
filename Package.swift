// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "SilkRoad",
    products: [
        .library(
            name: "SilkRoad",
            targets: ["SilkRoad"]),
    ],
    dependencies: [
        
    ],
    targets: [
        .target(
            name: "SilkRoad",
            dependencies: []),
        .testTarget(
            name: "SilkRoadTests",
            dependencies: ["SilkRoad"]),
    ]
)
