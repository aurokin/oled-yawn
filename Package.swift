// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "OLEDYawn",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "oled-yawn", targets: ["oled-yawn"]),
        .library(name: "OLEDYawnCore", targets: ["OLEDYawnCore"]),
    ],
    targets: [
        .target(name: "OLEDYawnCore"),
        .executableTarget(
            name: "oled-yawn",
            dependencies: ["OLEDYawnCore"],
            linkerSettings: [
                .linkedFramework("CoreDisplay"),
                .linkedFramework("IOKit"),
            ]
        ),
        .testTarget(
            name: "OLEDYawnCoreTests",
            dependencies: ["OLEDYawnCore"]
        ),
    ]
)
