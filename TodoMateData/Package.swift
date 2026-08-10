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
    .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.11.1"),
  ],
  targets: [
    .target(
      name: "TodoMateData",
      dependencies: [
        "TodoMateDomain",
        .product(name: "TodoMateApplication", package: "TodoMateDomain"),
        "Common",
        .product(name: "GRDB", package: "GRDB.swift"),
      ],
    ),
    .executableTarget(
      name: "GRDBReadOnlyProjectionProbe",
      dependencies: ["TodoMateData", "TodoMateDomain"],
    ),
    .testTarget(
      name: "TodoMateDataTests",
      dependencies: [
        "TodoMateData",
        .product(name: "TodoMateApplication", package: "TodoMateDomain"),
        .product(name: "GRDB", package: "GRDB.swift"),
      ],
    ),
  ],
)
