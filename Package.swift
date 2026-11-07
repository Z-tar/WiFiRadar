// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WiFiRadar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "WiFiRadar", targets: ["WiFiRadar"])
    ],
    targets: [
        .executableTarget(
            name: "WiFiRadar",
            path: "Sources"
        )
    ]
)
