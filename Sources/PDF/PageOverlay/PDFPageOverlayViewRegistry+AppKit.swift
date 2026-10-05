// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

#if canImport(AppKit)
  import AppKit
  import PDFKit
  import SwiftUI

  @MainActor
  struct PDFPageOverlayViewRegistryItem {
    let page: PDFPage
    let hostingView: NSHostingView<AnyView>

    func update(content: AnyView) {
      hostingView.rootView = content
    }

    func removeOverlayViewFromSuperview() {
      hostingView.removeFromSuperview()
    }

    var overlayView: NSView {
      hostingView
    }
  }

  extension PDFPageOverlayViewRegistry {
    mutating func overlayView(
      for page: PDFPage,
      contentProvider: @escaping PDFPageOverlayViewContentProvider
    ) -> NSView? {
      guard let content = contentProvider(page) else {
        return nil
      }

      return platformOverlayView(for: page, content: content)
    }

    private mutating func platformOverlayView(for page: PDFPage, content: AnyView) -> NSView {
      let pageIdentifier = ObjectIdentifier(page)

      if let registryItem = overlayViewRegistryItems[pageIdentifier] {
        registryItem.update(content: content)
        return registryItem.overlayView
      }

      let registryItem = makeOverlayView(for: page, content: content)
      overlayViewRegistryItems[pageIdentifier] = registryItem
      return registryItem.overlayView
    }

    private func makeOverlayView(
      for page: PDFPage,
      content: AnyView
    ) -> PDFPageOverlayViewRegistryItem {
      let hostingView = NSHostingView(rootView: content)
      hostingView.wantsLayer = true
      hostingView.layer?.backgroundColor = NSColor.clear.cgColor
      return PDFPageOverlayViewRegistryItem(page: page, hostingView: hostingView)
    }
  }
#endif
