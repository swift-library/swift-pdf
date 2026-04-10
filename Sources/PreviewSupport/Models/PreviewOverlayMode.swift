#if DEBUG && canImport(SwiftUI)
  import Foundation

  enum PreviewOverlayMode: String, CaseIterable, Identifiable {
    case off = "Off"
    case badge = "Badge"
    case interactive = "Interactive"

    var id: String { rawValue }
  }
#endif
