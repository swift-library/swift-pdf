import PDFKit
import SwiftUI

public typealias PDFPageOverlayViewRelease = @MainActor (_ page: PDFPage) -> Void
public typealias PDFPageOverlayViewContentProvider = @MainActor (_ page: PDFPage) -> AnyView?

@MainActor
extension PDFViewContainer {
  func configurePageOverlayViewProvider(_ pdfView: PDFView, coordinator: Coordinator) {
    pdfView.pageOverlayViewProvider = coordinator
  }
}
