// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "PDF",
  platforms: [
    .iOS("17.0"),
    .macOS("14.0"),
    .visionOS("1.0"),
  ],
  products: [
    .library(
      name: "PDF",
      targets: ["PDF"]
    ),
    .library(
      name: "PreviewSupport",
      targets: ["PreviewSupport"]
    )
  ],
  targets: [
    .target(
      name: "PDF",
      path: "Sources/PDF"
    ),
    .target(
      name: "PreviewSupport",
      dependencies: ["PDF"],
      path: "Sources/PreviewSupport"
    ),
    .testTarget(
      name: "PDFTests",
      dependencies: ["PDF"]
    ),
  ]
)
