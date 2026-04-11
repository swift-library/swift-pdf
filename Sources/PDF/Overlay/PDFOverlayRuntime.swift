import PDFKit
import SwiftUI

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

@MainActor
final class PDFOverlayRuntime {
  private var contentProvider: PDFPageOverlayContentProvider = { _ in nil }
  private var release: PDFPageOverlayRelease = { _ in }
  private var hostRegistry = PDFOverlayHostRegistry()

  func updateCallbacks(
    contentProvider: @escaping PDFPageOverlayContentProvider,
    release: @escaping PDFPageOverlayRelease
  ) {
    self.contentProvider = contentProvider
    self.release = release
  }

  func refreshHostsIfNeeded() {
    hostRegistry.refresh(
      contentProvider: overlayContent(for:),
      release: releaseOverlay(for:)
    )
  }

  func clearHosts() {
    hostRegistry.clear(release: releaseOverlay(for:))
  }

  #if canImport(UIKit)
    func overlayView(for page: PDFPage) -> UIView? {
      hostRegistry.overlayView(for: page, contentProvider: overlayContent(for:))
    }
  #elseif canImport(AppKit)
    func overlayView(for page: PDFPage) -> NSView? {
      hostRegistry.overlayView(for: page, contentProvider: overlayContent(for:))
    }
  #endif

  func willDisplayOverlayView(for page: PDFPage) {
    hostRegistry.willDisplayOverlayView(for: page, contentProvider: overlayContent(for:))
  }

  func didEndDisplayingOverlayView(for page: PDFPage) {
    hostRegistry.didEndDisplayingOverlayView(for: page, release: releaseOverlay(for:))
  }

  private func overlayContent(for page: PDFPage) -> AnyView? {
    contentProvider(page)
  }

  private func releaseOverlay(for page: PDFPage) {
    release(page)
  }
}
