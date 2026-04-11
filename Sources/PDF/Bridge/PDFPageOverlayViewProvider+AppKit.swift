#if canImport(AppKit)
  import AppKit
  import PDFKit
  import SwiftUI

  @MainActor
  extension PDFViewContainer.Coordinator: @preconcurrency PDFPageOverlayViewProvider {
    public func pdfView(_ view: PDFView, overlayViewFor page: PDFPage) -> NSView? {
      overlayView(for: page)
    }

    public func pdfView(
      _ pdfView: PDFView,
      willDisplayOverlayView overlayView: NSView,
      for page: PDFPage
    ) {
      willDisplayOverlayView(for: page)
    }

    public func pdfView(
      _ pdfView: PDFView,
      willEndDisplayingOverlayView overlayView: NSView,
      for page: PDFPage
    ) {
      didEndDisplayingOverlayView(for: page)
    }
  }
#endif
