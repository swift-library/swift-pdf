import PDFKit
import SwiftUI

@MainActor
extension PDFViewContainer.Coordinator {
  func overlayContent(for page: PDFPage) -> AnyView? {
    overlayContentProvider(page)
  }

  func releaseOverlay(for page: PDFPage) {
    overlayRelease(page)
  }
}
