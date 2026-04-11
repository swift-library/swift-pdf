#if DEBUG && canImport(SwiftUI) && PDF_INTERNAL_PREVIEW
  import Foundation
  import PDFKit

  enum PreviewFixtures {
    static let fixtureRelativePath = "Tests/PDFTests/Fixtures/drawingwithquartz2d.pdf"

    static func fixtureURL(
      filePath: StaticString = #filePath
    ) -> URL? {
      guard let repositoryRootURL = repositoryRootURL(startingAt: filePath) else {
        return nil
      }

      let pdfURL = repositoryRootURL.appendingPathComponent(fixtureRelativePath)
      guard FileManager.default.fileExists(atPath: pdfURL.path) else {
        return nil
      }

      return pdfURL
    }

    static func previewSource(
      filePath: StaticString = #filePath
    ) -> PDFDocument.Representation? {
      if let fixtureURL = fixtureURL(filePath: filePath),
        let document = PDFDocument(url: fixtureURL)
      {
        return .document(document)
      }
      return nil
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
