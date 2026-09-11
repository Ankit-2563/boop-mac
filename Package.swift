// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Boop",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/httpswift/swifter.git", exact: "1.5.0")
    ],
    targets: [
        .executableTarget(
            name: "Boop",
            dependencies: [
                .product(name: "Swifter", package: "swifter")
            ],
            path: "Sources/Boop"
        )
    ]
)
