// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import PDFKit
import SwiftUI

@MainActor
extension PDFViewBase where Base: View {
  public func displayMode(_ displayMode: PDFDisplayMode) -> some View {
    base.environment(\.displayMode, displayMode)
  }

  public func displayDirection(_ displayDirection: PDFDisplayDirection) -> some View {
    base.environment(\.displayDirection, displayDirection)
  }

  public func autoScales(_ autoScales: Bool) -> some View {
    base.environment(\.autoScales, autoScales)
  }

  public func isInMarkupMode(_ isInMarkupMode: Bool) -> some View {
    base.environment(\.isInMarkupMode, isInMarkupMode)
  }
}
