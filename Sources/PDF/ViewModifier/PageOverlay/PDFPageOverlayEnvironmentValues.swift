import SwiftUI

@MainActor
struct PDFPageOverlayContentProviderEnvironmentValue {
  let provider: PDFPageOverlayViewContentProvider
}

@MainActor
struct PDFPageOverlayReleaseEnvironmentValue {
  let release: PDFPageOverlayViewRelease
}

extension EnvironmentValues {
  @Entry
  var pageOverlayContentProvider: PDFPageOverlayContentProviderEnvironmentValue?

  @Entry
  var pageOverlayRelease: PDFPageOverlayReleaseEnvironmentValue?
}
