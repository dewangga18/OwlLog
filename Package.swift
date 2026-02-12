// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OwlLog",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "OwlLog",
            targets: ["OwlLog"]
        ),
        .library(
            name: "OwlLogUI",
            targets: ["OwlLogUI"]
        ),
    ],
    targets: [
        .target(
            name: "OwlLog"
        ),
        .target(
            name: "OwlLogUI",
            dependencies: ["OwlLog"]
        ),
    ]
)
