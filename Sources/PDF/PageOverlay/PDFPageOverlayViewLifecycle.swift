import PDFKit
import SwiftUI

@MainActor
final class PDFPageOverlayViewLifecycle {
  private var contentProvider: PDFPageOverlayViewContentProvider = { _ in nil }
  private var release: PDFPageOverlayViewRelease = { _ in }
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
      contentProvider: overlayContent(for:),
      release: releaseOverlay(for:)
    )
  }

  func clearOverlayViews() {
    viewRegistry.clear(release: releaseOverlay(for:))
  }

  func willDisplayOverlayView(for page: PDFPage) {
    viewRegistry.willDisplayOverlayView(for: page, contentProvider: overlayContent(for:))
  }

  func didEndDisplayingOverlayView(for page: PDFPage) {
    viewRegistry.didEndDisplayingOverlayView(for: page, release: releaseOverlay(for:))
  }

  func overlayContent(for page: PDFPage) -> AnyView? {
    contentProvider(page)
  }

  private func releaseOverlay(for page: PDFPage) {
    release(page)
  }
}
