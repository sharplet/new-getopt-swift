// swift-tools-version:5.1

import PackageDescription

let package = Package(
  name: "Getopt",
  targets: [
    .target(name: "Getopt"),
    .testTarget(name: "GetoptTests", dependencies: ["Getopt"]),
  ]
)
