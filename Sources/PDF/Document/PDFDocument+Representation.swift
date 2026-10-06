// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import Foundation
import PDFKit

extension PDFDocument {
  /// A document source resolved when its representation changes in a ``PDF`` viewer.
  /// Data and URL failures resolve to no document; they are not thrown to the caller.
  public enum Representation {
    /// Reuses an existing PDFKit document instance.
    case document(PDFDocument)
    /// Asks PDFKit to decode the supplied PDF bytes.
    case data(Data)
    /// Asks PDFKit to load a document from the supplied file URL.
    case fileURL(URL)

    func resolveDocument() -> PDFDocument? {
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
