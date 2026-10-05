// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

#if canImport(AppKit)
  import AppKit
  import PDFKit
  import SwiftUI

  @MainActor
  extension PDFViewContainer.Coordinator: @preconcurrency PDFPageOverlayViewProvider {
    func pdfView(_ view: PDFView, overlayViewFor page: PDFPage) -> NSView? {
      overlayView(for: page)
    }

    func pdfView(
      _ pdfView: PDFView,
      willDisplayOverlayView overlayView: NSView,
      for page: PDFPage
    ) {
      willDisplayOverlayView(for: page)
    }

    func pdfView(
      _ pdfView: PDFView,
      willEndDisplayingOverlayView overlayView: NSView,
      for page: PDFPage
    ) {
      didEndDisplayingOverlayView(for: page)
    }
  }
#endif
