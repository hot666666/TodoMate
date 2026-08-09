// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "TodoMateData",
  platforms: [.macOS(.v26)],
  products: [
    .library(
      name: "TodoMateData",
      targets: ["TodoMateData"],
    ),
  ],
  dependencies: [
    .package(path: "../TodoMateDomain"),
    .package(path: "../Common"),
  ],
  targets: [
    .target(
      name: "TodoMateData",
      dependencies: [
        "TodoMateDomain",
        "Common",
      ],
    ),
    .testTarget(
      name: "TodoMateDataTests",
      dependencies: ["TodoMateData"],
    ),
  ],
)
