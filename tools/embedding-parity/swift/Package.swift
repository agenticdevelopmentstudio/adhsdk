// swift-tools-version: 6.4
//
// The Apple side of the semantic search parity spike: the same bundle, run
// with ONNX Runtime and the swift-transformers tokenizer, checked against the
// bundle's golden set on macOS and in the iOS simulator.

import PackageDescription

// Every dependency comes from the machine's one shared package folder,
// installed by externalpackages at the version its list names.
let shared = (Context.environment["HOME"] ?? "") + "/Library/Developer/SharedPackages"

let package = Package(
    name: "EmbeddingParity",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "EmbeddingParity", targets: ["EmbeddingParity"]),
    ],
    dependencies: [
        .package(path: shared + "/onnxruntime-swift-package-manager"),
        .package(path: shared + "/swift-transformers"),
    ],
    targets: [
        .target(
            name: "EmbeddingParity",
            dependencies: [
                .product(name: "onnxruntime", package: "onnxruntime-swift-package-manager"),
                .product(name: "Tokenizers", package: "swift-transformers"),
            ]
        ),
        .testTarget(name: "EmbeddingParityTests", dependencies: ["EmbeddingParity"]),
    ]
)
