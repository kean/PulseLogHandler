// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "PulseLogHandler",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .macOS(.v11),
        .watchOS(.v7)
    ],
    products: [
        .library(name: "PulseLogHandler", targets: ["PulseLogHandler"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.2.0"),
        .package(url: "https://github.com/kean/pulse.git", from: "3.0.0")
    ],
    targets: [
        .target(name: "PulseLogHandler", dependencies: [
            .product(name: "Pulse", package: "Pulse"),
            .product(name: "Logging", package: "swift-log")
        ]),
        .testTarget(name: "PulseLogHandlerTests", dependencies: ["PulseLogHandler"])
    ]
)
