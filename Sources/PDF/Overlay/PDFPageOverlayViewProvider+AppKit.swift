#if canImport(AppKit)
  import AppKit
  import PDFKit
  import SwiftUI

  @MainActor
  extension PDFViewContainer {
    func configurePageOverlayViewProvider(_ pdfView: PDFView, coordinator: Coordinator) {
      pdfView.pageOverlayViewProvider = coordinator
    }
  }

  @MainActor
  extension PDFViewContainer.Coordinator: @preconcurrency PDFPageOverlayViewProvider {
    public func pdfView(_ view: PDFView, overlayViewFor page: PDFPage) -> NSView? {
      overlayHostRegistry.overlayView(for: page, contentProvider: overlayContent(for:))
    }

    public func pdfView(
      _ pdfView: PDFView,
      willDisplayOverlayView overlayView: NSView,
      for page: PDFPage
    ) {
      overlayHostRegistry.willDisplayOverlayView(for: page, contentProvider: overlayContent(for:))
    }

    public func pdfView(
      _ pdfView: PDFView,
      willEndDisplayingOverlayView overlayView: NSView,
      for page: PDFPage
    ) {
      overlayHostRegistry.didEndDisplayingOverlayView(for: page, release: releaseOverlay(for:))
    }
  }
#endif
