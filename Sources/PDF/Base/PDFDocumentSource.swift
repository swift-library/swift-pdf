import Foundation
import PDFKit

public enum PDFDocumentSource {
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

extension PDFDocumentSource {
  enum Identity: Equatable {
    case object(ObjectIdentifier)
    case data(length: Int, hash: Int)
    case fileURL(URL)
  }

  var identity: Identity {
    switch self {
    case .document(let document):
      return .object(ObjectIdentifier(document))
    case .data(let data):
      return .data(length: data.count, hash: data.hashValue)
    case .fileURL(let fileURL):
      return .fileURL(fileURL.standardizedFileURL)
    }
  }
}
