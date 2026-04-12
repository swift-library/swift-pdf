import PDFKit

extension PDFDocument {
  @MainActor
  final class CachedLoader {
    private var cachedIdentifier: Representation.Identifier?
    private var mountedDocumentIdentifier: ObjectIdentifier?

    enum Change: Equatable {
      case unchanged
      case documentChanged
    }

    func flush() {
      cachedIdentifier = nil
      mountedDocumentIdentifier = nil
    }

    @discardableResult
    func load(
      representation: Representation,
      into pdfView: PDFView?
    ) -> Change {
      guard let pdfView else {
        return .unchanged
      }

      let identifier = representation.identifier
      if cachedIdentifier != identifier {
        cachedIdentifier = identifier
        pdfView.document = representation.resolveDocument()
      }

      let currentDocumentIdentifier = pdfView.document.map(ObjectIdentifier.init)
      guard mountedDocumentIdentifier != currentDocumentIdentifier else {
        return .unchanged
      }

      mountedDocumentIdentifier = currentDocumentIdentifier
      return .documentChanged
    }
  }
}
