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
    private let pageStateBindingSynchronizer = PDFPageStateBindingSynchronizer()
    private let pageNavigation = PDFPageNavigation()
    private let searchRuntime = PDFSearchRuntime()
    private let searchBindingSynchronizer = PDFSearchBindingSynchronizer()
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
        pageStateBindingSynchronizer.reset()
        searchRuntime.reset()
        searchBindingSynchronizer.reset()
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
      pageStateBindingSynchronizer.reset()
      searchRuntime.reset()
      searchBindingSynchronizer.reset()
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

      searchRuntime.markDocumentChanged()
      return true
    }

    private func refreshPageBindings(applyExternalPage: Bool) {
      if applyExternalPage {
        let pageToNavigate = pageStateBindingSynchronizer.externalPageToNavigateIfNeeded(
          on: pdfView,
          pageIndexBinding: pageBindings.pageIndex
        )
        if let pageToNavigate {
          pageNavigation.navigate(to: pageToNavigate, on: pdfView)
        }
      }

      pageStateBindingSynchronizer.publish(
        on: pdfView,
        pageIndexBinding: pageBindings.pageIndex,
        pageCountBinding: pageBindings.pageCount
      )
    }

    private func refreshSearchBindings() {
      searchBindingSynchronizer.sync(
        on: pdfView,
        runtime: searchRuntime,
        queryBinding: searchBindings.query,
        selectionBinding: searchBindings.selection,
        resultCountBinding: searchBindings.resultCount,
        optionsBinding: searchBindings.options,
        resultsBinding: searchBindings.results,
        navigateToSearchMatch: { [weak self] target in
          guard let self else {
            return
          }

          self.pageNavigation.navigate(to: target, on: self.pdfView)
        }
      )
    }
  }
}
