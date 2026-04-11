#if DEBUG && canImport(SwiftUI) && PDF_INTERNAL_PREVIEW
  import Foundation

  enum PreviewOverlayMode: String, CaseIterable, Identifiable {
    case off = "Off"
    case badge = "Badge"
    case interactive = "Interactive"

    var id: String { rawValue }
  }
#endif
