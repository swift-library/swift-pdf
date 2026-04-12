import PDFKit
import SwiftUI

@MainActor
final class PDFPageOverlayViewLifecycle {
  private(set) var contentProvider: PDFPageOverlayViewContentProvider = { _ in nil }
  private(set) var release: PDFPageOverlayViewRelease = { _ in }
  var viewRegistry = PDFPageOverlayViewRegistry()

  func updateCallbacks(
    contentProvider: @escaping PDFPageOverlayViewContentProvider,
    release: @escaping PDFPageOverlayViewRelease
  ) {
    self.contentProvider = contentProvider
    self.release = release
  }

  func refreshOverlayViewsIfNeeded() {
    viewRegistry.refresh(
      contentProvider: contentProvider,
      release: release
    )
  }

  func clearOverlayViews() {
    viewRegistry.clear(release: release)
  }

  func willDisplayOverlayView(for page: PDFPage) {
    viewRegistry.willDisplayOverlayView(for: page, contentProvider: contentProvider)
  }

  func didEndDisplayingOverlayView(for page: PDFPage) {
    viewRegistry.didEndDisplayingOverlayView(for: page, release: release)
  }
}
