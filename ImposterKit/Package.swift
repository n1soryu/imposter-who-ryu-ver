// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ImposterKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ImposterKit", targets: ["ImposterKit"]),
        .library(name: "ImposterHost", targets: ["ImposterHost"]),
        .executable(name: "imposter-host-dev", targets: ["imposter-host-dev"]),
    ],
    targets: [
        .target(name: "ImposterKit", resources: [.copy("Resources/Categories")]),
        .target(name: "ImposterHost", dependencies: ["ImposterKit"], resources: [.copy("Web")]),
        .executableTarget(name: "imposter-host-dev", dependencies: ["ImposterKit", "ImposterHost"]),
        .testTarget(name: "ImposterKitTests", dependencies: ["ImposterKit"]),
        .testTarget(name: "ImposterHostTests", dependencies: ["ImposterHost", "ImposterKit"]),
    ]
)
