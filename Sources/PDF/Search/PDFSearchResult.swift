// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import CoreGraphics
import PDFKit

public struct PDFSearchResult: Equatable, Sendable {
  public let index: Int
  public let pageIndex: Int
  public let bounds: CGRect
  public let text: String

  public init(index: Int, pageIndex: Int, bounds: CGRect, text: String) {
    self.index = index
    self.pageIndex = pageIndex
    self.bounds = bounds
    self.text = text
  }
}
