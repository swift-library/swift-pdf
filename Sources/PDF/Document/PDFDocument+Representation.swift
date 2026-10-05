// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import Foundation
import PDFKit

extension PDFDocument {
  public enum Representation {
    case document(PDFDocument)
    case data(Data)
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
