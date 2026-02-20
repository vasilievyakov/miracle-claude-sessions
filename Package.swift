// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ClaudeSessions",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ClaudeSessions",
            path: "Sources",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "ClaudeSessionsTests",
            dependencies: ["ClaudeSessions"],
            resources: [.copy("Fixtures")],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
