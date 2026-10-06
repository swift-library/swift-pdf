// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import PDFKit
import SwiftUI

@MainActor
extension PDFViewBase where Base: View {
  /// Sets PDFKit's page layout mode for descendant viewers.
  public func displayMode(_ displayMode: PDFDisplayMode) -> some View {
    base.environment(\.displayMode, displayMode)
  }

  /// Sets the direction in which PDFKit lays out pages in descendant viewers.
  public func displayDirection(_ displayDirection: PDFDisplayDirection) -> some View {
    base.environment(\.displayDirection, displayDirection)
  }

  /// Lets PDFKit choose a fitting scale when enabled.
  public func autoScales(_ autoScales: Bool) -> some View {
    base.environment(\.autoScales, autoScales)
  }

  /// Sets PDFKit's markup mode for descendant viewers.
  public func isInMarkupMode(_ isInMarkupMode: Bool) -> some View {
    base.environment(\.isInMarkupMode, isInMarkupMode)
  }
}
