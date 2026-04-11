import PDFKit

extension PDFDocument.Representation {
  @MainActor
  final class Loader {
    private var cachedIdentifier: Identifier?

    func resetCachedIdentifier() {
      cachedIdentifier = nil
    }

    func load(
      representation: PDFDocument.Representation,
      into pdfView: PDFView?
    ) -> Bool {
      guard let pdfView else {
        return false
      }

      let identifier = representation.identifier
      guard cachedIdentifier != identifier else {
        return false
      }

      cachedIdentifier = identifier
      pdfView.document = representation.resolveDocument()
      return true
    }
  }
}
