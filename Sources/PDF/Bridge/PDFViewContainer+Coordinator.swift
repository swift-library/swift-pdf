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

    private var publishers = Set<AnyCancellable>()

    private let documentLoader = PDFDocument.CachedLoader()
    private var searchEngine: PDFSearchEngine!
    private let searchBindingDriver = PDFSearchBindingDriver()
    private let pageOverlayViewLifecycle = PDFPageOverlayViewLifecycle()

    private var pageBindings = PDFPageBindings()
    private var searchBindings = PDFSearchBindings()

    func bind(
      view pdfView: PDFView,
      from source: PDFDocument.Representation,
      pageBindings: PDFPageBindings,
      searchBindings: PDFSearchBindings
    ) {
      let viewChanged = self.pdfView !== pdfView

      if viewChanged {
        removePublishers()
        pageOverlayViewLifecycle.clearOverlayViews()
        self.pdfView = pdfView
        installPublishers(for: pdfView)
        documentLoader.flush()
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
      }

      refreshPageBindings(in: pdfView)
      refreshSearchBindings()
    }

    func detach() {
      removePublishers()

      pdfView = nil
      pageBindings = PDFPageBindings()
      searchBindings = PDFSearchBindings()
      searchEngine = nil
      documentLoader.flush()
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

    private func installPublishers(for pdfView: PDFView) {
      removePublishers()

      NotificationCenter.default.publisher(
        for: Notification.Name.PDFViewPageChanged,
        object: pdfView
      )
      .sink { [weak self] _ in
        MainActor.assumeIsolated {
          self.map { pdfView.publish($0.pageBindings) }
        }
      }
      .store(in: &publishers)

      NotificationCenter.default.publisher(
        for: Notification.Name.PDFViewScaleChanged,
        object: pdfView
      )
      .sink { [weak self] _ in
        MainActor.assumeIsolated {
          self.map { pdfView.publish($0.pageBindings) }
        }
      }
      .store(in: &publishers)
    }

    private func removePublishers() {
      publishers.removeAll()
    }

    private func refreshPageBindings(in pdfView: PDFView) {
      if let pageIndex = pageBindings.pageIndex?.wrappedValue {
        pdfView.go(to: pageIndex)
      }

      pdfView.publish(pageBindings)
    }

    private func refreshSearchBindings() {
      guard let searchEngine else {
        return
      }

      let decision = searchBindingDriver.performFind(
        engine: searchEngine,
        searchBindings: searchBindings
      )

      switch decision {
      case .publish:
        break
      case .clearSelection:
        pdfView?.setCurrentSelection(nil, animate: false)
      case .focus(let selection, _):
        guard let pdfView else {
          break
        }
        pdfView.setCurrentSelection(selection, animate: true)
        pdfView.go(to: selection)
      }
    }
  }
}
