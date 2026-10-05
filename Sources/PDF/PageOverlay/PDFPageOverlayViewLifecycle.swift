// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import Foundation
import PDFKit
import SwiftUI

@MainActor
final class PDFPageOverlayViewLifecycle {
  private(set) var contentProvider: PDFPageOverlayViewContentProvider = { _ in nil }
  private(set) var release: PDFPageOverlayViewRelease = { _ in }
  private(set) var hasContentProvider = false
  var viewRegistry = PDFPageOverlayViewRegistry()

  private var refreshWorkItem: DispatchWorkItem?

  func updateCallbacks(
    contentProvider: PDFPageOverlayViewContentProvider?,
    release: PDFPageOverlayViewRelease?
  ) {
    guard let contentProvider else {
      clearOverlayViews()
      self.contentProvider = { _ in nil }
      self.release = { _ in }
      hasContentProvider = false
      return
    }

    self.contentProvider = contentProvider
    self.release = release ?? { _ in }
    hasContentProvider = true
  }

  func refreshOverlayViewsIfNeeded() {
    refreshWorkItem?.cancel()
    refreshWorkItem = nil
    guard hasContentProvider else { return }

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
