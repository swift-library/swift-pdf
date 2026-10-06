// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import SwiftUI

@MainActor
extension PDFViewBase where Base: View {
  /// Reports the settled zero-based page index; writing this binding does not navigate.
  /// An absent or empty document reports zero. Use ``PDFViewProxy/goToPage(at:)`` to navigate.
  public func currentPage(_ pageIndex: Binding<Int>) -> some View {
    base.environment(\.currentPageBinding, pageIndex)
  }

  /// Reports the document page count, or zero without a document; the binding is output only.
  public func pageCount(_ count: Binding<Int>) -> some View {
    base.environment(\.pageCountBinding, count)
  }

  /// Reports PDFKit's settled scale factor; writing the binding does not change zoom.
  /// Use ``PDFViewProxy/setScaleFactor(_:)`` for zoom commands.
  public func scaleFactor(_ scaleFactor: Binding<CGFloat>) -> some View {
    base.environment(\.scaleFactorBinding, scaleFactor)
  }
}
