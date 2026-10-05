// swift-tools-version: 6.2
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import PackageDescription

let package = Package(
  name: "PDFViewer",
  platforms: [
    .iOS(.v18),
    .macOS(.v15),
    .visionOS(.v2),
  ],
  dependencies: [
    .package(name: "swift-pdf", path: "../..")
  ],
  targets: [
    .executableTarget(
      name: "PDFViewer",
      dependencies: [
        .product(name: "PDF", package: "swift-pdf")
      ]
    )
  ]
)
