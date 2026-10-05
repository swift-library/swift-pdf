import Foundation

enum OverlayMode: String, CaseIterable, Identifiable {
  case off = "Off"
  case badge = "Badge"
  case interactive = "Interactive"

  var id: String { rawValue }
}
