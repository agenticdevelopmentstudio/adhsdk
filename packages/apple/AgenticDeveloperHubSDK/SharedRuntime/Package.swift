// swift-tools-version: 6.4
import Foundation
import PackageDescription

let shared = NSHomeDirectory() + "/Library/Developer/SharedPackages/"

// One dynamic library for the third-party packages that two SDK frameworks both
// need: MCP (Core) and swift-transformers' Tokenizers (SemanticSearchStore) reach
// the same EventSource and NIO. A package product linked into two frameworks is
// copied into each, and dyld then reports those classes implemented in both. A
// product declared `.dynamic` is one image that every framework links, so there is
// one copy. The version ranges here must match project.yml's `packages:`.
let package = Package(
    name: "ADHSharedRuntime",
    platforms: [.macOS("26.0"), .iOS("26.0")],
    products: [
        .library(name: "ADHSharedRuntime", type: .dynamic, targets: ["ADHSharedRuntime"])
    ],
    dependencies: [
        .package(path: shared + "swift-sdk"),
        .package(path: shared + "swift-transformers")
    ],
    targets: [
        .target(
            name: "ADHSharedRuntime",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk"),
                .product(name: "Tokenizers", package: "swift-transformers")
            ]
        )
    ]
)
