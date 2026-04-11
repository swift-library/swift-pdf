#if DEBUG && canImport(SwiftUI) && PDF_INTERNAL_PREVIEW
  import SwiftUI

  #Preview("Fixture PDF (Interactive)") {
    PDFViewInteractivePreview(source: .fileURL(PreviewFixtures.fixtureURL()!))
  }
#endif
