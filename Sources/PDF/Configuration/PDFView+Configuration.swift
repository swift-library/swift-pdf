// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import PDFKit

extension PDFView {
  @MainActor
  func configure(using configuration: PDFViewConfiguration) {
    if displayMode != configuration.displayMode {
      displayMode = configuration.displayMode
    }
    if displayDirection != configuration.displayDirection {
      displayDirection = configuration.displayDirection
    }
    if autoScales != configuration.autoScales {
      autoScales = configuration.autoScales
    }
    if isInMarkupMode != configuration.isInMarkupMode {
      isInMarkupMode = configuration.isInMarkupMode
    }
  }
}
