// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SnapshotTestCase",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "SnapshotTestCase",
            targets: ["SnapshotTestCase"]
        ),
    ],
    targets: [
        .target(
            name: "SnapshotTestCase",
            dependencies: []
        ),
        .testTarget(
            name: "SnapshotTestCaseTests",
            dependencies: [
                "SnapshotTestCase",
            ]
        )
    ]
)
