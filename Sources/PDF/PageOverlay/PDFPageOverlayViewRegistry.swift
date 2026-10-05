// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import PDFKit
import SwiftUI

#if canImport(UIKit) || canImport(AppKit)
  @MainActor
  struct PDFPageOverlayViewRegistry {
    var overlayViewRegistryItems: [ObjectIdentifier: PDFPageOverlayViewRegistryItem] = [:]

    mutating func refresh(
      contentProvider: @escaping PDFPageOverlayViewContentProvider,
      release: @escaping PDFPageOverlayViewRelease
    ) {
      for key in Array(overlayViewRegistryItems.keys) {
        guard let registryItem = overlayViewRegistryItems[key] else {
          continue
        }

        if let content = contentProvider(registryItem.page) {
          registryItem.update(content: content)
        } else {
          removeOverlayView(forKey: key, release: release)
        }
      }
    }

    mutating func clear(release: @escaping PDFPageOverlayViewRelease) {
      for key in Array(overlayViewRegistryItems.keys) {
        removeOverlayView(forKey: key, release: release)
      }
    }

    mutating func willDisplayOverlayView(
      for page: PDFPage,
      contentProvider: @escaping PDFPageOverlayViewContentProvider
    ) {
      let key = ObjectIdentifier(page)
      guard let registryItem = overlayViewRegistryItems[key], let content = contentProvider(page)
      else {
        return
      }

      registryItem.update(content: content)
    }

    mutating func didEndDisplayingOverlayView(
      for page: PDFPage,
      release: @escaping PDFPageOverlayViewRelease
    ) {
      _ = removeOverlayView(for: page, release: release)
    }

    @discardableResult
    private mutating func removeOverlayView(
      for page: PDFPage,
      release: @escaping PDFPageOverlayViewRelease
    ) -> Bool {
      let key = ObjectIdentifier(page)
      return removeOverlayView(forKey: key, release: release)
    }

    @discardableResult
    private mutating func removeOverlayView(
      forKey key: ObjectIdentifier,
      release: @escaping PDFPageOverlayViewRelease
    ) -> Bool {
      guard let registryItem = overlayViewRegistryItems.removeValue(forKey: key) else {
        return false
      }

      registryItem.removeOverlayViewFromSuperview()
      release(registryItem.page)
      return true
    }
  }
#else
  @MainActor
  struct PDFPageOverlayViewRegistry {
    mutating func refresh(
      contentProvider: @escaping PDFPageOverlayViewContentProvider,
      release: @escaping PDFPageOverlayViewRelease
    ) {}

    mutating func willDisplayOverlayView(
      for page: PDFPage,
      contentProvider: @escaping PDFPageOverlayViewContentProvider
    ) {}

    mutating func clear(release: @escaping PDFPageOverlayViewRelease) {}

    mutating func didEndDisplayingOverlayView(
      for page: PDFPage,
      release: @escaping PDFPageOverlayViewRelease
    ) {}
  }
#endif
