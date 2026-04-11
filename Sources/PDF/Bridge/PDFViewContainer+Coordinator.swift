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

    private var pageChangedObserver: NSObjectProtocol?
    private var scaleChangedObserver: NSObjectProtocol?

    private let documentLoader = PDFDocumentLoader()
    private let pageBindingSynchronizer = PDFPageBindingSynchronizer()
    private let searchRuntime = PDFSearchRuntime()
    private let searchBindingSynchronizer = PDFSearchBindingSynchronizer()
    private let pageOverlayViewLifecycle = PDFPageOverlayViewLifecycle()

    private var pageBindings = PDFPageBindings()
    private var searchBindings = PDFSearchBindings()

    func bind(
      pdfView: PDFView,
      source: PDFDocumentSource,
      pageBindings: PDFPageBindings,
      searchBindings: PDFSearchBindings
    ) {
      let viewChanged = self.pdfView !== pdfView

      if viewChanged {
        removeObservers()
        pageOverlayViewLifecycle.clearOverlayViews()
        self.pdfView = pdfView
        installObservers(for: pdfView)
        documentLoader.resetLoadedSourceIdentity()
        pageBindingSynchronizer.reset()
        searchRuntime.reset()
        searchBindingSynchronizer.reset()
      }

      self.pageBindings = pageBindings
      self.searchBindings = searchBindings

      _ = loadSourceIfNeeded(source, forceReload: false)

      refreshPageBindings(applyExternalPage: true)
      refreshSearchBindings()
    }

    func loadDocumentIfNeeded(_ source: PDFDocumentSource) {
      _ = loadSourceIfNeeded(source, forceReload: false)
      refreshPageBindings(applyExternalPage: true)
      refreshSearchBindings()
    }

    func detach() {
      removeObservers()

      pdfView = nil
      pageBindings = PDFPageBindings()
      searchBindings = PDFSearchBindings()
      pageBindingSynchronizer.reset()
      searchRuntime.reset()
      searchBindingSynchronizer.reset()
      documentLoader.resetLoadedSourceIdentity()
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

    private func installObservers(for pdfView: PDFView) {
      let center = NotificationCenter.default

      pageChangedObserver = center.addObserver(
        forName: Notification.Name.PDFViewPageChanged,
        object: pdfView,
        queue: .main
      ) { [weak self] _ in
        Task { @MainActor [weak self] in
          self?.refreshPageBindings(applyExternalPage: false)
        }
      }

      scaleChangedObserver = center.addObserver(
        forName: Notification.Name.PDFViewScaleChanged,
        object: pdfView,
        queue: .main
      ) { [weak self] _ in
        Task { @MainActor [weak self] in
          self?.refreshPageBindings(applyExternalPage: false)
        }
      }
    }

    private func removeObservers() {
      let center = NotificationCenter.default

      if let pageChangedObserver {
        center.removeObserver(pageChangedObserver)
        self.pageChangedObserver = nil
      }

      if let scaleChangedObserver {
        center.removeObserver(scaleChangedObserver)
        self.scaleChangedObserver = nil
      }
    }

    @discardableResult
    private func loadSourceIfNeeded(_ source: PDFDocumentSource, forceReload: Bool = true) -> Bool {
      let didLoad = documentLoader.load(source: source, forceReload: forceReload, into: pdfView)
      guard didLoad else {
        return false
      }

      searchRuntime.markDocumentChanged()
      return true
    }

    private func refreshPageBindings(applyExternalPage: Bool) {
      if applyExternalPage {
        pageBindingSynchronizer.applyExternalPageIndexIfNeeded(
          on: pdfView,
          pageIndexBinding: pageBindings.pageIndex
        )
      }

      pageBindingSynchronizer.publish(
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

          self.pageBindingSynchronizer.navigateToSearchMatch(on: self.pdfView, target: target)
        }
      )
    }
  }
}
