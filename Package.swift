// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "PortBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "PortBarCore", targets: ["PortBarCore"]),
        .executable(name: "PortBar", targets: ["PortBar"])
    ],
    targets: [
        .target(
            name: "PortBarCore",
            path: "Sources/PortBarCore"
        ),
        .executableTarget(
            name: "PortBar",
            dependencies: ["PortBarCore"],
            path: "Sources/PortBar",
            linkerSettings: [
                .linkedFramework("SwiftUI"),
                .linkedFramework("AppKit")
            ]
        ),
        .testTarget(
            name: "PortBarCoreTests",
            dependencies: ["PortBarCore"],
            path: "Tests/PortBarCoreTests"
        )
    ]
)
