// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VividAI",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "VividAI",
            targets: ["VividAI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
        .package(url: "https://github.com/replicate/replicate-swift.git", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "VividAI",
            dependencies: [
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "Replicate", package: "replicate-swift"),
            ]
        ),
        .testTarget(
            name: "VividAITests",
            dependencies: ["VividAI"]
        ),
    ]
)
