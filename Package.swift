// swift-tools-version: 6.3
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import PackageDescription

let package = Package(
  name: "swift-pdf",
  platforms: [
    .iOS(.v18),
    .macOS(.v15),
    .visionOS(.v2),
  ],
  products: [
    .library(
      name: "PDF",
      targets: ["PDF"]
    )
  ],
  targets: [
    .target(
      name: "PDF"
    ),
    .testTarget(
      name: "PDFTests",
      dependencies: ["PDF"]
    ),
  ]
)
