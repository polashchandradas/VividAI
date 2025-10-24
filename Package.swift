// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VividAI",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "VividAI",
            targets: ["VividAI"]),
    ],
    dependencies: [
        // Firebase dependencies
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
    ],
    targets: [
        .target(
            name: "VividAI",
            dependencies: [
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
            ]),
        .testTarget(
            name: "VividAITests",
            dependencies: ["VividAI"]),
    ]
)
