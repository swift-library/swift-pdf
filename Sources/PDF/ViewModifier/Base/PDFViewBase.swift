// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import PDFKit
import SwiftUI

/// A namespace for PDF-specific extensions.
public struct PDFViewBase<Base> {
  let base: Base

  init(_ base: Base) {
    self.base = base
  }
}

extension PDFViewBase: Sendable where Base: Sendable {}

extension View {
  /// Accesses PDF modifiers that configure descendant viewers through their environment.
  public var pdf: PDFViewBase<Self> {
    .init(self)
  }
}
