#if DEBUG && canImport(SwiftUI) && PDF_INTERNAL_PREVIEW
  import Foundation
  import PDFKit
  import SwiftUI

  @MainActor
  private let requiredPreviewSource: PDFDocument.Representation = {
    guard let source = PreviewFixtures.previewSource() else {
      fatalError(
        "Unable to create preview source. Expected fixture at repository path: \(PreviewFixtures.fixtureRelativePath)"
      )
    }
    return source
  }()

  #Preview("Fixture PDF (Interactive)") {
    PDFViewInteractivePreview(source: requiredPreviewSource)
  }
#endif
