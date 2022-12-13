// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "SnapshotTest",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "SnapshotTest",
            targets: ["SnapshotTest"]
        )
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SnapshotTest",
            dependencies: []
        )
    ]
)
