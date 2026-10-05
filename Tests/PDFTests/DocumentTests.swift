// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import Foundation
import PDFKit
import Testing

@testable import PDF

extension PDFTests {
  @Suite("Document")
  @MainActor
  final class Document: PDFKitSuite {
    @Test
    func documentSourceDocumentCasePreservesObjectIdentity() {
      let document = PDFDocument()
      let source = PDFDocument.Representation.document(document)

      #expect(source.resolveDocument() === document)
    }

    @Test
    func documentSourceDataCaseBuildsReadableDocument() throws {
      let fixtureData = try Data(contentsOf: fixturePDFURL())
      let source = PDFDocument.Representation.data(fixtureData)

      let document = try #require(source.resolveDocument())
      #expect(document.pageCount > 0)
    }

    @Test
    func documentSourceFileURLCaseBuildsReadableDocument() throws {
      let source = PDFDocument.Representation.fileURL(try fixturePDFURL())

      let document = try #require(source.resolveDocument())
      #expect(document.pageCount > 0)
    }

    @Test
    func repeatedLoadWithSameDataSourceDoesNotRemountDocument() throws {
      let fixtureData = try Data(contentsOf: fixturePDFURL())
      let source = PDFDocument.Representation.data(fixtureData)
      let loader = PDFDocument.CachedLoader()
      let pdfView = PDFView()

      #expect(loader.load(representation: source, into: pdfView) == .documentChanged)
      let firstDocument = try #require(pdfView.document)

      #expect(loader.load(representation: source, into: pdfView) == .unchanged)
      #expect(pdfView.document === firstDocument)
    }
  }
}
