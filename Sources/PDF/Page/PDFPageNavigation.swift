import CoreGraphics
import PDFKit

@MainActor
struct PDFPageNavigation {
  struct Destination {
    let selection: PDFSelection
    let page: PDFPage?
    let bounds: CGRect
  }

  func navigate(to page: PDFPage?, on pdfView: PDFView?) {
    guard let pdfView, let page, pdfView.document != nil else {
      return
    }

    pdfView.go(to: page)
  }

  func navigate(to destination: Destination?, on pdfView: PDFView?) {
    guard let pdfView, let destination else {
      return
    }

    if let page = destination.page, !destination.bounds.isNull && !destination.bounds.isEmpty {
      pdfView.go(to: destination.bounds, on: page)
      return
    }

    pdfView.go(to: destination.selection)
  }
}
