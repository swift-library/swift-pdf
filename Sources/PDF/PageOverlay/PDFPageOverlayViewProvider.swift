import PDFKit
import SwiftUI

public typealias PDFPageOverlayViewRelease = @MainActor (_ page: PDFPage) -> Void
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
