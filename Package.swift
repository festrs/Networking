// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Networking",
  platforms: [.iOS(.v10),
              .macOS(.v10_15)],
  products: [
    .library(
      name: "Networking",
      targets: ["Networking"]),
  ],
  dependencies: [
    .package(url: "https://github.com/WeTransfer/Mocker.git", .upToNextMajor(from: "2.3.0"))
  ],
  targets: [
    .target(
      name: "Networking",
      dependencies: []),
    .testTarget(
      name: "NetworkingTests",
      dependencies: ["Networking", "Mocker"]),
  ]
)
