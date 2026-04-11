import Foundation
import PDFKit

extension PDFDocument {
  public enum Representation {
    case document(PDFDocument)
    case data(Data)
    case fileURL(URL)

    public func resolveDocument() -> PDFDocument? {
      switch self {
      case .document(let document):
        return document
      case .data(let data):
        return PDFDocument(data: data)
      case .fileURL(let fileURL):
        return PDFDocument(url: fileURL)
      }
    }
  }
}
