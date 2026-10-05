// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

#if canImport(UIKit)
  import PDFKit
  import SwiftUI

  @MainActor
  extension PDFViewContainer.Coordinator: @preconcurrency PDFPageOverlayViewProvider {
    func pdfView(_ view: PDFView, overlayViewFor page: PDFPage) -> UIView? {
      overlayView(for: page)
    }

    func pdfView(
      _ pdfView: PDFView,
      willDisplayOverlayView overlayView: UIView,
      for page: PDFPage
    ) {
      willDisplayOverlayView(for: page)
    }

    func pdfView(
      _ pdfView: PDFView,
      willEndDisplayingOverlayView overlayView: UIView,
      for page: PDFPage
    ) {
      didEndDisplayingOverlayView(for: page)
    }
  }
#endif
