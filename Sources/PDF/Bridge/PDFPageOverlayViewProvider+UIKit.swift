#if canImport(UIKit)
  import PDFKit
  import SwiftUI

  @MainActor
  extension PDFViewContainer.Coordinator: @preconcurrency PDFPageOverlayViewProvider {
    public func pdfView(_ view: PDFView, overlayViewFor page: PDFPage) -> UIView? {
      overlayView(for: page)
    }

    public func pdfView(
      _ pdfView: PDFView,
      willDisplayOverlayView overlayView: UIView,
      for page: PDFPage
    ) {
      willDisplayOverlayView(for: page)
    }

    public func pdfView(
      _ pdfView: PDFView,
      willEndDisplayingOverlayView overlayView: UIView,
      for page: PDFPage
    ) {
      didEndDisplayingOverlayView(for: page)
    }
  }
#endif
