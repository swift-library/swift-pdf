import PDFKit

@MainActor
extension PDFViewContainer {
  func configurePageOverlayViewProvider(_ pdfView: PDFView, coordinator: Coordinator) {
    pdfView.pageOverlayViewProvider = coordinator
  }
}
