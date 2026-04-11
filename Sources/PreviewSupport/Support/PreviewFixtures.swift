#if DEBUG
  import CoreGraphics
  import Foundation
  import PDF
  import PDFKit

  enum PreviewFixtures {
    static let defaultRootPDFName = "drawingwithquartz2d.pdf"

    static func rootPDFURL(
      named pdfName: String = defaultRootPDFName,
      filePath: StaticString = #filePath
    ) -> URL? {
      guard let repositoryRootURL = repositoryRootURL(startingAt: filePath) else {
        return nil
      }

      let pdfURL = repositoryRootURL.appendingPathComponent(pdfName)
      guard FileManager.default.fileExists(atPath: pdfURL.path) else {
        return nil
      }

      return pdfURL
    }

    static func previewSource(
      named pdfName: String = defaultRootPDFName,
      filePath: StaticString = #filePath
    ) -> PDFDocument.Representation? {
      if let fixtureURL = rootPDFURL(named: pdfName, filePath: filePath),
        let document = PDFDocument(url: fixtureURL)
      {
        return .document(document)
      }

      if let fallback = fallbackDocument() {
        return .document(fallback)
      }

      return nil
    }

    private static func fallbackDocument() -> PDFDocument? {
      guard let data = fallbackPDFData() else {
        return nil
      }
      return PDFDocument(data: data)
    }

    private static func fallbackPDFData() -> Data? {
      let data = NSMutableData()
      var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)

      guard let consumer = CGDataConsumer(data: data as CFMutableData),
        let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
      else {
        return nil
      }

      context.beginPDFPage(nil)
      context.setFillColor(gray: 1, alpha: 1)
      context.fill(mediaBox)
      context.endPDFPage()
      context.closePDF()
      return data as Data
    }

    private static func repositoryRootURL(startingAt filePath: StaticString) -> URL? {
      var currentURL = URL(fileURLWithPath: "\(filePath)").deletingLastPathComponent()

      while true {
        let packageManifestURL = currentURL.appendingPathComponent("Package.swift")
        if FileManager.default.fileExists(atPath: packageManifestURL.path) {
          return currentURL
        }

        let parentURL = currentURL.deletingLastPathComponent()
        if parentURL.path == currentURL.path {
          return nil
        }

        currentURL = parentURL
      }
    }
  }
#endif
