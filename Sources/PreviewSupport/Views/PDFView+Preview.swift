#if DEBUG && canImport(SwiftUI)
  import Foundation
  import PDF
  import PDFKit
  import SwiftUI

  @MainActor
  private let requiredPreviewSource: PDFDocument.Representation = {
    guard let source = PreviewFixtures.previewSource() else {
      fatalError(
        "Unable to create preview source. Expected fixture at repo root: \(PreviewFixtures.defaultRootPDFName)"
      )
    }
    return source
  }()

  #Preview("Root Fixture PDF (Interactive)") {
    PDFViewInteractivePreview(source: requiredPreviewSource)
  }
#endif
