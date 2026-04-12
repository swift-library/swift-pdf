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

    private let pdfViewNotificationPublisher = PDFViewNotificationPublisher()
    private var observerPublishers = Set<AnyCancellable>()

    private let documentLoader = PDFDocument.Representation.Loader()
    private var searchEngine = PDFSearchEngine(document: PDFDocument())
    private let searchBindingDriver = PDFSearchBindingDriver()
    private let pageOverlayViewLifecycle = PDFPageOverlayViewLifecycle()

    private var pageBindings = PDFPageBindings()
    private var searchBindings = PDFSearchBindings()

    func bind(
      pdfView: PDFView,
      source: PDFDocument.Representation,
      pageBindings: PDFPageBindings,
      searchBindings: PDFSearchBindings
    ) {
      let viewChanged = self.pdfView !== pdfView

      if viewChanged {
        removePublishers()
        pageOverlayViewLifecycle.clearOverlayViews()
        self.pdfView = pdfView
        installPublishers(for: pdfView)
        documentLoader.resetCachedIdentifier()
        searchEngine = PDFSearchEngine(document: pdfView.document ?? PDFDocument())
      }

      self.pageBindings = pageBindings
      self.searchBindings = searchBindings

      _ = reloadDocumentIfNeeded(source)

      refreshPageBindings(applyExternalPage: true)
      refreshSearchBindings()
    }

    func loadDocumentIfNeeded(_ source: PDFDocument.Representation) {
      _ = reloadDocumentIfNeeded(source)
      refreshPageBindings(applyExternalPage: true)
      refreshSearchBindings()
    }

    func detach() {
      removePublishers()

      pdfView = nil
      pageBindings = PDFPageBindings()
      searchBindings = PDFSearchBindings()
      searchEngine = PDFSearchEngine(document: PDFDocument())
      documentLoader.resetCachedIdentifier()
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

      pdfViewNotificationPublisher.onPageChanged(
        for: pdfView,
        observer: self,
        storeIn: &observerPublishers,
        perform: Coordinator.handlePageOrScaleChanged
      )

      pdfViewNotificationPublisher.onScaleChanged(
        for: pdfView,
        observer: self,
        storeIn: &observerPublishers,
        perform: Coordinator.handlePageOrScaleChanged
      )
    }

    private func removePublishers() {
      observerPublishers.removeAll()
    }

    private func handlePageOrScaleChanged() {
      refreshPageBindings(applyExternalPage: false)
    }

    @discardableResult
    private func reloadDocumentIfNeeded(_ source: PDFDocument.Representation) -> Bool {
      let didLoad = documentLoader.load(
        representation: source,
        into: pdfView
      )
      guard didLoad else {
        return false
      }

      searchEngine = PDFSearchEngine(document: pdfView?.document ?? PDFDocument())
      return true
    }

    private func refreshPageBindings(applyExternalPage: Bool) {
      if applyExternalPage,
        let pdfView,
        let requestedPageIndex = pageBindings.pageIndex?.wrappedValue,
        let destination = pdfView.destination(at: requestedPageIndex)
      {
        pdfView.go(to: destination)
      }

      if let pdfView {
        pdfView.publish(pageBindings)
        return
      }

      if let pageCountBinding = pageBindings.pageCount, pageCountBinding.wrappedValue != 0 {
        pageCountBinding.wrappedValue = 0
      }
      if let pageIndexBinding = pageBindings.pageIndex, pageIndexBinding.wrappedValue != 0 {
        pageIndexBinding.wrappedValue = 0
      }
    }

    private func refreshSearchBindings() {
      let searchDecision = searchBindingDriver.performFind(
        engine: searchEngine,
        searchBindings: searchBindings
      )

      switch searchDecision {
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
