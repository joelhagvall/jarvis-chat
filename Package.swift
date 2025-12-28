// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OllamaChat",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "OllamaChat", targets: ["OllamaChat"])
    ],
    targets: [
        .executableTarget(
            name: "OllamaChat",
            path: "Sources"
        ),
        .testTarget(
            name: "OllamaChatTests",
            dependencies: ["OllamaChat"]
        )
    ]
)
