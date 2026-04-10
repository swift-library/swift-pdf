import SwiftUI

extension EnvironmentValues {
  @Entry
  var pageOverlayContentProvider: PDFPageOverlayContentProvider = { _ in nil }

  @Entry
  var pageOverlayRelease: PDFPageOverlayRelease = { _ in }
}
