// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "SilkRoad",
    products: [
        .library(
            name: "SilkRoadFramework",
            targets: ["SilkRoadFramework"]
        ),
    ],
    dependencies: [
        
    ],
    targets: [
        .target(
            name: "SilkRoadFramework",
            dependencies: []
        ),
        .testTarget(
            name: "SilkRoadTests",
            dependencies: ["SilkRoadFramework"]
        ),
    ]
)
