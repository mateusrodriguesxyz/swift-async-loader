// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-async-loader",
    platforms: [
        .iOS(.v15),
        .macCatalyst(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "AsyncLoader",
            targets: ["AsyncLoader"]),
    ],
    targets: [
        .target(
            name: "AsyncLoader"),
        .testTarget(
            name: "AsyncLoaderTests",
            dependencies: ["AsyncLoader"]),
    ]
)
