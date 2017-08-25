// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "Monzo",
    dependencies: [
        .Package(url: "https://github.com/open-swift/S4.git", majorVersion: 0, minor: 12)
    ]
)
