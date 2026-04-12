#if canImport(UIKit)
  import PDFKit
  import UIKit

  extension PDFPageOverlayViewLifecycle {
    func overlayView(for page: PDFPage) -> UIView? {
      viewRegistry.overlayView(for: page, contentProvider: contentProvider)
    }
  }
#endif
