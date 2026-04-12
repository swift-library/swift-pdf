#if canImport(AppKit)
  import AppKit
  import PDFKit

  extension PDFPageOverlayViewLifecycle {
    func overlayView(for page: PDFPage) -> NSView? {
      return viewRegistry.overlayView(for: page, contentProvider: contentProvider)
    }
  }
#endif
