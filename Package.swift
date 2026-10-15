// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "AnthroPlus",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "AnthroPlusApp", targets: ["AnthroPlusApp"]),
    ],
    targets: [
        .target(
            name: "AnthroCore",
            resources: [.copy("Resources/who")]
        ),
        .target(name: "AnthroStore", dependencies: ["AnthroCore"]),
        .target(name: "AnthroIO", dependencies: ["AnthroCore", "AnthroAnalysis"]),
        .target(name: "AnthroAnalysis", dependencies: ["AnthroCore"]),
        .target(
            name: "AnthroFeatures",
            dependencies: ["AnthroCore", "AnthroStore", "AnthroIO", "AnthroAnalysis"]
        ),
        .executableTarget(name: "AnthroPlusApp", dependencies: ["AnthroFeatures"]),

        .testTarget(
            name: "AnthroCoreTests",
            dependencies: ["AnthroCore"],
            resources: [.copy("Fixtures")]
        ),
        .testTarget(name: "AnthroStoreTests", dependencies: ["AnthroStore", "AnthroCore"]),
        .testTarget(
            name: "AnthroIOTests",
            dependencies: ["AnthroIO"],
            resources: [.copy("Fixtures")]
        ),
        .testTarget(name: "AnthroAnalysisTests", dependencies: ["AnthroAnalysis"]),
        .testTarget(name: "AnthroFeaturesTests", dependencies: ["AnthroFeatures", "AnthroStore"]),
    ]
)
