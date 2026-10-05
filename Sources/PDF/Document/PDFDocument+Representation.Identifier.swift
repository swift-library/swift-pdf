// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import Foundation
import PDFKit

extension PDFDocument.Representation {
  enum Identifier: Equatable {
    case object(ObjectIdentifier)
    case data(length: Int, hash: Int)
    case fileURL(URL)
  }

  var identifier: Identifier {
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
