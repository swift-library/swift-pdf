import Foundation
import PDFKit
import SwiftUI

@MainActor
final class PDFPageOverlayViewLifecycle {
  private(set) var contentProvider: PDFPageOverlayViewContentProvider = { _ in nil }
  private(set) var release: PDFPageOverlayViewRelease = { _ in }
  var viewRegistry = PDFPageOverlayViewRegistry()

  private var refreshWorkItem: DispatchWorkItem?

  func updateCallbacks(
    contentProvider: @escaping PDFPageOverlayViewContentProvider,
    release: @escaping PDFPageOverlayViewRelease
  ) {
    self.contentProvider = contentProvider
    self.release = release
  }

  func refreshOverlayViewsIfNeeded() {
    refreshWorkItem?.cancel()

    let refreshWorkItem = DispatchWorkItem { [weak self] in
      guard let self else {
        return
      }

      self.viewRegistry.refresh(
        contentProvider: self.contentProvider,
        release: self.release
      )
    }

    self.refreshWorkItem = refreshWorkItem
    DispatchQueue.main.async(execute: refreshWorkItem)
  }

  func clearOverlayViews() {
    refreshWorkItem?.cancel()
    refreshWorkItem = nil
    viewRegistry.clear(release: release)
  }

  func willDisplayOverlayView(for page: PDFPage) {
    viewRegistry.willDisplayOverlayView(for: page, contentProvider: contentProvider)
  }

  func didEndDisplayingOverlayView(for page: PDFPage) {
    viewRegistry.didEndDisplayingOverlayView(for: page, release: release)
  }
}
