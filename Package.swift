// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "arstdhneio",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "arstdhneio", targets: ["arstdhneio"]),
        .library(name: "arstdhneioCore", targets: ["arstdhneioCore"])
    ],
    targets: [
        .target(
            name: "arstdhneioCore",
            path: "Sources/AsdfghjklCore"
        ),
        .executableTarget(
            name: "arstdhneio",
            dependencies: ["arstdhneioCore"],
            path: "Sources/Asdfghjkl"
        ),
        .testTarget(
            name: "arstdhneioTests",
            dependencies: ["arstdhneioCore"],
            path: "Tests/AsdfghjklTests"
        ),
        .testTarget(
            name: "arstdhneioAppTests",
            dependencies: ["arstdhneio"],
            path: "Tests/arstdhneioAppTests"
        )
    ]
)
