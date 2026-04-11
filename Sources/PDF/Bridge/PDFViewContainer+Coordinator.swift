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
    private let overlayRuntime = PDFOverlayRuntime()

    private var pageBindings = PDFPageBindings()
    private var searchBindings = PDFSearchBindings()

    func bind(
      pdfView: PDFView,
      initialSource: PDFDocumentSource,
      pageBindings: PDFPageBindings,
      searchBindings: PDFSearchBindings
    ) {
      let viewChanged = self.pdfView !== pdfView

      if viewChanged {
        removeObservers()
        overlayRuntime.clearHosts()
        self.pdfView = pdfView
        installObservers(for: pdfView)
        documentLoader.resetLoadedSourceIdentity()
        pageBindingSynchronizer.reset()
        searchRuntime.reset()
        searchBindingSynchronizer.reset()
      }

      self.pageBindings = pageBindings
      self.searchBindings = searchBindings

      _ = loadDocument(from: initialSource, forceReload: false)

      refreshPageBindings(applyExternalPage: true)
      refreshSearchBindings()
    }

    func loadDocumentIfNeeded(_ source: PDFDocumentSource) {
      _ = loadDocument(from: source, forceReload: false)
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
      overlayRuntime.clearHosts()
    }

    func updateOverlayCallbacks(_ callbacks: PDFOverlayCallbacks) {
      overlayRuntime.updateCallbacks(
        contentProvider: callbacks.contentProvider,
        release: callbacks.release
      )
      overlayRuntime.refreshHostsIfNeeded()
    }

    #if canImport(UIKit)
      func overlayView(for page: PDFPage) -> UIView? {
        overlayRuntime.overlayView(for: page)
      }
    #elseif canImport(AppKit)
      func overlayView(for page: PDFPage) -> NSView? {
        overlayRuntime.overlayView(for: page)
      }
    #endif

    func willDisplayOverlayView(for page: PDFPage) {
      overlayRuntime.willDisplayOverlayView(for: page)
    }

    func didEndDisplayingOverlayView(for page: PDFPage) {
      overlayRuntime.didEndDisplayingOverlayView(for: page)
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
    private func loadDocument(from source: PDFDocumentSource, forceReload: Bool = true) -> Bool {
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
        resultsBinding: searchBindings.results
      )
    }
  }
}
