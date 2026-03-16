// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Carbon",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Carbon", targets: ["CarbonApp"]),
    ],
    targets: [
        .target(
            name: "CarbonEngine",
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedLibrary("sqlite3"),
            ]
        ),
        .target(
            name: "CarbonUI",
            dependencies: ["CarbonEngine"]
        ),
        .executableTarget(
            name: "CarbonApp",
            dependencies: ["CarbonUI"]
        ),
        .testTarget(
            name: "CarbonEngineTests",
            dependencies: ["CarbonEngine"]
        ),
    ]
)
