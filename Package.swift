// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "SnapshotTestCase",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "SnapshotTestCase",
            targets: ["SnapshotTestCase"]
        )
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SnapshotTestCase",
            dependencies: []
        )
    ]
)
