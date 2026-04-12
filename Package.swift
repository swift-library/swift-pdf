// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "swift-pdf",
  platforms: [
    .iOS("17.0"),
    .macOS("14.0"),
    .visionOS("1.0"),
  ],
  products: [
    .library(
      name: "PDF",
      targets: ["PDF"]
    )
  ],
  targets: [
    .target(
      name: "PDF",
      path: "Sources/PDF",
      swiftSettings: [
        .define("PDF_INTERNAL_PREVIEW", .when(configuration: .debug))
      ]
    ),
    .testTarget(
      name: "PDFTests",
      dependencies: ["PDF"],
      exclude: ["Fixtures/drawingwithquartz2d.pdf"]
    ),
  ]
)
