// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ZakatEngine",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "ZakatEngine", targets: ["ZakatEngine"]),
    ],
    targets: [
        .target(name: "ZakatEngine"),
        .testTarget(
            name: "ZakatEngineTests",
            dependencies: ["ZakatEngine"]
        ),
    ]
)
