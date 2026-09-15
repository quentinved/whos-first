// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FingrCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "FingrCore", targets: ["FingrCore"])],
    targets: [
        .target(name: "FingrCore"),
        .testTarget(name: "FingrCoreTests", dependencies: ["FingrCore"])
    ]
)
