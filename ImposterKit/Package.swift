// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ImposterKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ImposterKit", targets: ["ImposterKit"]),
    ],
    targets: [
        .target(name: "ImposterKit"),
        .testTarget(name: "ImposterKitTests", dependencies: ["ImposterKit"]),
    ]
)
