// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-migration",
    platforms: [.macOS(.v13)], // macOS 환경에서 실행 가능하도록 설정
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", "11.8.0" ..< "11.9.0"),
    ],
    targets: [
        .executableTarget(
            name: "swift-migration",  // Sources/name/main.swift @main
            dependencies: [  // 설치하기로 한 Firebase SDK에서 필요한 라이브러리 설정
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
            ]),       
    ]
)
