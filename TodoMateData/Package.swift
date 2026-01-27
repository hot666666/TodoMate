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
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "12.7.0"),
    .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: "9.0.0"),
    .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0"),
  ],
  targets: [
    .target(
      name: "TodoMateData",
      dependencies: [
        "TodoMateDomain",
        "Common",
        .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
        .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
        .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
        .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
        .product(name: "GRDB", package: "GRDB.swift"),
      ],
    ),
    // SwiftData 등 Firebase 외 Data 레이어 테스트
    .testTarget(
      name: "TodoMateDataTests",
      dependencies: ["TodoMateData"],
    ),
    // Firebase 에뮬레이터를 사용하는 통합 테스트
    .testTarget(
      name: "TodoMateDataFirebaseTests",
      dependencies: ["TodoMateData"],
    ),
  ],
)
