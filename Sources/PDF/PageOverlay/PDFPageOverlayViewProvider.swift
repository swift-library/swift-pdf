// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import PDFKit
import SwiftUI

/// Releases resources for a page when its hosted overlay is removed or the viewer is dismantled.
public typealias PDFPageOverlayViewRelease = @MainActor (_ page: PDFPage) -> Void
/// Creates or refreshes a page overlay on the main actor; returning `nil` omits that overlay.
public typealias PDFPageOverlayViewContentProvider = @MainActor (_ page: PDFPage) -> AnyView?

@MainActor
extension PDFViewContainer.Coordinator {
  func configurePageOverlayViewProvider(
    in pdfView: PDFView,
    forceRewire: Bool = false
  ) {
    guard pageOverlayViewLifecycle.hasContentProvider else {
      if pdfView.pageOverlayViewProvider === self {
        pdfView.pageOverlayViewProvider = nil
      }
      return
    }

    guard forceRewire || pdfView.pageOverlayViewProvider !== self else {
      return
    }

    if forceRewire, pdfView.pageOverlayViewProvider === self {
      pdfView.pageOverlayViewProvider = nil
    }
    pdfView.pageOverlayViewProvider = self
  }
}
