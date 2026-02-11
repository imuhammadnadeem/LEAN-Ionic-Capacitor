// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LeanIonicCapacitor",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "LeanIonicCapacitor",
            targets: ["LEANPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "7.0.0"),
        .package(url: "https://github.com/leantechnologies/link-sdk-ios-distribution", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "LEANPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                .product(name: "LeanSDK", package: "link-sdk-ios-distribution")
            ],
            path: "ios/Sources/LEANPlugin"),
        .testTarget(
            name: "LEANPluginTests",
            dependencies: ["LEANPlugin"],
            path: "ios/Tests/LEANPluginTests")
    ]
)
