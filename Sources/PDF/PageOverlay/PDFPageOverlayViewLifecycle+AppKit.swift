#if canImport(AppKit)
  import AppKit
  import PDFKit

  extension PDFPageOverlayViewLifecycle {
    func overlayView(for page: PDFPage) -> NSView? {
      viewRegistry.overlayView(for: page, contentProvider: overlayContent(for:))
    }
  }
#endif
