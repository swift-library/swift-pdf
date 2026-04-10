import PDFKit
import SwiftUI

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

@MainActor
struct PDFOverlayHostRegistry {
  #if canImport(UIKit)
    private struct SwiftUIOverlayHost {
      let page: PDFPage
      let hostingController: UIHostingController<AnyView>
    }

    private var hosts: [ObjectIdentifier: SwiftUIOverlayHost] = [:]

    mutating func refresh(
      contentProvider: @escaping PDFPageOverlayContentProvider,
      release: @escaping PDFPageOverlayRelease
    ) {
      for key in Array(hosts.keys) {
        guard let host = hosts[key] else {
          continue
        }

        if let content = contentProvider(host.page) {
          host.hostingController.rootView = content
        } else {
          removeHost(forKey: key, release: release)
        }
      }
    }

    mutating func clear(release: @escaping PDFPageOverlayRelease) {
      for key in Array(hosts.keys) {
        removeHost(forKey: key, release: release)
      }
    }

    mutating func overlayView(
      for page: PDFPage,
      contentProvider: @escaping PDFPageOverlayContentProvider
    ) -> UIView? {
      guard let content = contentProvider(page) else {
        return nil
      }
      return swiftUIOverlayView(for: page, content: content)
    }

    mutating func willDisplayOverlayView(
      for page: PDFPage,
      contentProvider: @escaping PDFPageOverlayContentProvider
    ) {
      let key = ObjectIdentifier(page)
      guard let host = hosts[key], let content = contentProvider(page) else {
        return
      }
      host.hostingController.rootView = content
    }

    mutating func didEndDisplayingOverlayView(
      for page: PDFPage,
      release: @escaping PDFPageOverlayRelease
    ) {
      _ = removeHost(for: page, release: release)
    }

    private mutating func swiftUIOverlayView(for page: PDFPage, content: AnyView) -> UIView {
      let pageIdentifier = ObjectIdentifier(page)

      if let host = hosts[pageIdentifier] {
        host.hostingController.rootView = content
        return host.hostingController.view
      }

      let hostingController = UIHostingController(rootView: content)
      hostingController.view.backgroundColor = .clear
      hostingController.view.isOpaque = false

      hosts[pageIdentifier] = SwiftUIOverlayHost(
        page: page,
        hostingController: hostingController
      )
      return hostingController.view
    }

    @discardableResult
    private mutating func removeHost(
      for page: PDFPage,
      release: @escaping PDFPageOverlayRelease
    ) -> Bool {
      let key = ObjectIdentifier(page)
      return removeHost(forKey: key, release: release)
    }

    @discardableResult
    private mutating func removeHost(
      forKey key: ObjectIdentifier,
      release: @escaping PDFPageOverlayRelease
    ) -> Bool {
      guard let host = hosts.removeValue(forKey: key) else {
        return false
      }

      host.hostingController.view.removeFromSuperview()
      release(host.page)
      return true
    }
  #elseif canImport(AppKit)
    private struct SwiftUIOverlayHost {
      let page: PDFPage
      let hostingView: NSHostingView<AnyView>
    }

    private var hosts: [ObjectIdentifier: SwiftUIOverlayHost] = [:]

    mutating func refresh(
      contentProvider: @escaping PDFPageOverlayContentProvider,
      release: @escaping PDFPageOverlayRelease
    ) {
      for key in Array(hosts.keys) {
        guard let host = hosts[key] else {
          continue
        }

        if let content = contentProvider(host.page) {
          host.hostingView.rootView = content
        } else {
          removeHost(forKey: key, release: release)
        }
      }
    }

    mutating func clear(release: @escaping PDFPageOverlayRelease) {
      for key in Array(hosts.keys) {
        removeHost(forKey: key, release: release)
      }
    }

    mutating func overlayView(
      for page: PDFPage,
      contentProvider: @escaping PDFPageOverlayContentProvider
    ) -> NSView? {
      guard let content = contentProvider(page) else {
        return nil
      }
      return swiftUIOverlayView(for: page, content: content)
    }

    mutating func willDisplayOverlayView(
      for page: PDFPage,
      contentProvider: @escaping PDFPageOverlayContentProvider
    ) {
      let key = ObjectIdentifier(page)
      guard let host = hosts[key], let content = contentProvider(page) else {
        return
      }
      host.hostingView.rootView = content
    }

    mutating func didEndDisplayingOverlayView(
      for page: PDFPage,
      release: @escaping PDFPageOverlayRelease
    ) {
      _ = removeHost(for: page, release: release)
    }

    private mutating func swiftUIOverlayView(for page: PDFPage, content: AnyView) -> NSView {
      let pageIdentifier = ObjectIdentifier(page)

      if let host = hosts[pageIdentifier] {
        host.hostingView.rootView = content
        return host.hostingView
      }

      let hostingView = NSHostingView(rootView: content)
      hostingView.wantsLayer = true
      hostingView.layer?.backgroundColor = NSColor.clear.cgColor

      hosts[pageIdentifier] = SwiftUIOverlayHost(
        page: page,
        hostingView: hostingView
      )
      return hostingView
    }

    @discardableResult
    private mutating func removeHost(
      for page: PDFPage,
      release: @escaping PDFPageOverlayRelease
    ) -> Bool {
      let key = ObjectIdentifier(page)
      return removeHost(forKey: key, release: release)
    }

    @discardableResult
    private mutating func removeHost(
      forKey key: ObjectIdentifier,
      release: @escaping PDFPageOverlayRelease
    ) -> Bool {
      guard let host = hosts.removeValue(forKey: key) else {
        return false
      }

      host.hostingView.removeFromSuperview()
      release(host.page)
      return true
    }
  #else
    mutating func refresh(
      contentProvider: @escaping PDFPageOverlayContentProvider,
      release: @escaping PDFPageOverlayRelease
    ) {}

    mutating func willDisplayOverlayView(
      for page: PDFPage,
      contentProvider: @escaping PDFPageOverlayContentProvider
    ) {}

    mutating func clear(release: @escaping PDFPageOverlayRelease) {}
  #endif
}
