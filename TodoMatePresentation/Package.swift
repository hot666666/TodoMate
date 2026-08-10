// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "TodoMatePresentation",
  platforms: [.macOS(.v26)],
  products: [
    .library(name: "TodoMatePresentation", targets: ["TodoMatePresentation"]),
    .library(name: "TodoMateUITestContracts", targets: ["TodoMateUITestContracts"]),
  ],
  dependencies: [
    .package(path: "../TodoMateDomain"),
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture",
      exact: "1.26.1"
    ),
  ],
  targets: [
    .target(name: "TodoMateUITestContracts"),
    .target(
      name: "TodoMatePresentation",
      dependencies: [
        .product(name: "TodoMateApplication", package: "TodoMateDomain"),
        .product(name: "TodoMateDomain", package: "TodoMateDomain"),
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
        "TodoMateUITestContracts",
      ]
    ),
    .testTarget(
      name: "TodoMatePresentationTests",
      dependencies: [
        "TodoMatePresentation",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
  ]
)
