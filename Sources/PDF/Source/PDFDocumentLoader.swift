import PDFKit

@MainActor
final class PDFDocumentLoader {
  private var loadedSourceIdentity: PDFDocumentSource.Identity?

  func resetLoadedSourceIdentity() {
    loadedSourceIdentity = nil
  }

  func load(source: PDFDocumentSource, forceReload: Bool, into pdfView: PDFView?) -> Bool {
    guard let pdfView else {
      return false
    }

    let sourceIdentity = source.identity
    guard forceReload || loadedSourceIdentity != sourceIdentity else {
      return false
    }

    loadedSourceIdentity = sourceIdentity
    pdfView.document = source.resolveDocument()
    return true
  }
}
