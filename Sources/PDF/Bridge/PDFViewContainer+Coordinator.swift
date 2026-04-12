import Combine
import PDFKit
import SwiftUI

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

extension PDFViewContainer {
  @MainActor
  public final class Coordinator: NSObject {
    private weak var pdfView: PDFView?
    private var proxy: PDFViewProxy? {
      didSet {
        oldValue?.relay = nil
        proxy?.relay = relay
      }
    }
    private var relay: PDFViewProxyRelay? {
      didSet {
        proxy?.relay = relay
      }
    }

    private var publishers = Set<AnyCancellable>()

    private let documentLoader = PDFDocument.CachedLoader()
    private let searchBindingDriver = PDFSearchBindingDriver()
    let pageOverlayViewLifecycle = PDFPageOverlayViewLifecycle()

    private var searchEngine: PDFSearchEngine?
    private var pageBindings = PDFPageBindings()
    private var searchBindings = PDFSearchBindings()

    func bind(
      view pdfView: PDFView,
      from source: PDFDocument.Representation,
      pageBindings: PDFPageBindings,
      searchBindings: PDFSearchBindings,
      proxy: PDFViewProxy?
    ) {
      let viewChanged = self.pdfView !== pdfView

      if viewChanged {
        removePublishers()
        relay = nil
        pageOverlayViewLifecycle.clearOverlayViews()
        self.pdfView = pdfView
        self.proxy = nil
        addPublishers(for: pdfView)
        documentLoader.flush()
        searchBindingDriver.reset()
        searchEngine = nil
      }

      self.pageBindings = pageBindings
      self.searchBindings = searchBindings

      if case .documentChanged = documentLoader.load(
        representation: source,
        into: pdfView
      ) {
        pageOverlayViewLifecycle.clearOverlayViews()
        searchEngine = pdfView.document.map(PDFSearchEngine.init(document:))
        configurePageOverlayViewProvider(in: pdfView)
      } else if searchEngine == nil {
        searchEngine = pdfView.document.map(PDFSearchEngine.init(document:))
      }

      self.proxy = proxy
      self.relay = PDFViewProxyRelay(
        pdfView: pdfView,
        pageBindings: pageBindings,
        searchBindings: searchBindings,
        searchBindingDriver: searchBindingDriver,
        searchEngine: searchEngine
      )
      pdfView.publishState(pageBindings)
      refreshSearchBindings(in: pdfView)
    }

    func detach() {
      removePublishers()
      relay = nil

      pdfView = nil
      proxy = nil
      pageBindings = PDFPageBindings()
      searchBindings = PDFSearchBindings()
      searchEngine = nil
      documentLoader.flush()
      searchBindingDriver.reset()
      pageOverlayViewLifecycle.clearOverlayViews()
    }

    func updatePageOverlayViewCallbacks(_ callbacks: PDFPageOverlayViewCallbacks) {
      pageOverlayViewLifecycle.updateCallbacks(
        contentProvider: callbacks.contentProvider,
        release: callbacks.release
      )
      pageOverlayViewLifecycle.refreshOverlayViewsIfNeeded()
    }

    #if canImport(UIKit)
      func overlayView(for page: PDFPage) -> UIView? {
        pageOverlayViewLifecycle.overlayView(for: page)
      }
    #elseif canImport(AppKit)
      func overlayView(for page: PDFPage) -> NSView? {
        pageOverlayViewLifecycle.overlayView(for: page)
      }
    #endif

    func willDisplayOverlayView(for page: PDFPage) {
      pageOverlayViewLifecycle.willDisplayOverlayView(for: page)
    }

    func didEndDisplayingOverlayView(for page: PDFPage) {
      pageOverlayViewLifecycle.didEndDisplayingOverlayView(for: page)
    }

    private func addPublishers(for pdfView: PDFView) {
      removePublishers()

      NotificationCenter.default.publisher(
        for: Notification.Name.PDFViewPageChanged,
        object: pdfView
      )
      .sink { [weak self] _ in
        MainActor.assumeIsolated {
          self.map { pdfView.publishState($0.pageBindings) }
        }
      }
      .store(in: &publishers)

      NotificationCenter.default.publisher(
        for: Notification.Name.PDFViewScaleChanged,
        object: pdfView
      )
      .sink { [weak self] _ in
        MainActor.assumeIsolated {
          self.map { pdfView.publishState($0.pageBindings) }
        }
      }
      .store(in: &publishers)
    }

    private func removePublishers() {
      publishers.removeAll()
    }

    private func refreshSearchBindings(in pdfView: PDFView) {
      guard let searchEngine else {
        return
      }

      guard searchEngine.performFind(
        query: searchBindings.query?.wrappedValue ?? "",
        options: searchBindings.options?.wrappedValue ?? []
      ) else {
        return
      }

      pdfView.setCurrentSelection(nil, animate: false)
      searchBindingDriver.publish(searchEngine.state, searchBindings: searchBindings)
    }
  }
}
