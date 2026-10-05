// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import CoreGraphics
import SwiftUI

@MainActor
struct PDFPageBindings {
  var currentPage: Binding<Int>?
  var pageCount: Binding<Int>?
  var scaleFactor: Binding<CGFloat>?

  init(
    currentPage: Binding<Int>? = nil,
    pageCount: Binding<Int>? = nil,
    scaleFactor: Binding<CGFloat>? = nil
  ) {
    self.currentPage = currentPage
    self.pageCount = pageCount
    self.scaleFactor = scaleFactor
  }
}
