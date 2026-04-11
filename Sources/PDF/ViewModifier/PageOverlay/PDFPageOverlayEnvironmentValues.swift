import SwiftUI

extension EnvironmentValues {
  @Entry
  var pageOverlayContentProvider: PDFPageOverlayViewContentProvider = { _ in nil }

  @Entry
  var pageOverlayRelease: PDFPageOverlayViewRelease = { _ in }
}
