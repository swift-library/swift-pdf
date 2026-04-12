import PDFKit
import SwiftUI

public typealias PDFPageOverlayViewRelease = @MainActor (_ page: PDFPage) -> Void
public typealias PDFPageOverlayViewContentProvider = @MainActor (_ page: PDFPage) -> AnyView?

@MainActor
extension PDFViewContainer.Coordinator {
  func configurePageOverlayViewProvider(in pdfView: PDFView) {
    // Force PDFKit to rewire the overlay provider even when the coordinator instance
    // is unchanged across document replacement, preview reload, or platform-specific remounts.
    pdfView.pageOverlayViewProvider = nil
    pdfView.pageOverlayViewProvider = self
  }
}
