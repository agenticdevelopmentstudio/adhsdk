// swift-tools-version: 5.7
//
// CodeEditLanguages 0.1.20 (upstream commit 331d5dbc5fc8513be5848fce8a2a312908f36a11),
// vendored so no build clones the upstream repo. Upstream commits its prebuilt
// CodeLanguagesContainer.xcframework.zip on every release, so a clone carries ~100
// copies of it (3.2 GB) to use one. Here the Swift sources live in git and the one
// zip is fetched by URL and checksum into SwiftPM's shared artifact cache.
//
// The directory name is the package identity: it must stay `CodeEditLanguages` so
// this local package replaces the remote one CodeEditSourceEditor depends on.
// To move to a new upstream version, see README.md beside this file.

import PackageDescription

let package = Package(
    name: "CodeEditLanguages",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "CodeEditLanguages",
            targets: ["CodeEditLanguages"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/ChimeHQ/SwiftTreeSitter.git",
            from: "0.9.0"
        ),
    ],
    targets: [
        .target(
            name: "CodeEditLanguages",
            dependencies: ["CodeLanguagesContainer", "SwiftTreeSitter"],
            resources: [
                .copy("Resources")
            ],
            linkerSettings: [.linkedLibrary("c++")]
        ),
        .binaryTarget(
            name: "CodeLanguagesContainer",
            url: "https://raw.githubusercontent.com/CodeEditApp/CodeEditLanguages/331d5dbc5fc8513be5848fce8a2a312908f36a11/CodeLanguagesContainer.xcframework.zip",
            checksum: "c6ee69d9d373a9c3cf93d239e05369d9b941275d31cd7956d0dc83b5a5c3e152"
        ),
    ]
)
