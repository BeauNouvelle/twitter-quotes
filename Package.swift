// swift-tools-version:5.2
import PackageDescription

let package = Package(
  name: "twitter-quotes",
  platforms: [
    .macOS(.v10_15)
  ],
  dependencies: [
    // 💧 A server-side Swift web framework.
    .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
    .package(url: "https://github.com/vapor/queues-redis-driver.git", from: "1.0.0")
  ],
  targets: [
    .target(
      name: "App",
      dependencies: [
        .product(name: "Vapor", package: "vapor"),
        .product(name: "QueuesRedisDriver", package: "queues-redis-driver")
      ],
      swiftSettings: [
        // Enable better optimizations when building in Release configuration. Despite the use of
        // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release builds.
        // See <https://github.com/swift-server/guides/blob/main/docs/building.md#building-for-production> for details.
        .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
      ]
    ),
    .target(name: "Run", dependencies: [.target(name: "App")])
  ]
)
