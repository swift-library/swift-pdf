// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import Combine
import PDFKit
import SwiftUI

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

enum PDFBindingPublicationTiming {
  case immediate
  case nextMainActorTurn
}

extension PDFViewContainer {
  @MainActor
  final class Coordinator: NSObject {
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
    private var bindingPublicationTiming = PDFBindingPublicationTiming.immediate
    private var deferredPagePublicationTask: Task<Void, Never>?
    private var deferredBindingSynchronizationTask: Task<Void, Never>?

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
      proxy: PDFViewProxy?,
      bindingPublicationTiming: PDFBindingPublicationTiming = .immediate
    ) {
      let viewChanged = self.pdfView !== pdfView

      if viewChanged {
        cancelDeferredBindingPublications()
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

      self.bindingPublicationTiming = bindingPublicationTiming
      self.pageBindings = pageBindings
      self.searchBindings = searchBindings

      let documentLoadResult = documentLoader.load(
        representation: source,
        into: pdfView
      )
      let documentChanged: Bool
      if case .documentChanged = documentLoadResult {
        pageOverlayViewLifecycle.clearOverlayViews()
        searchEngine = pdfView.document.map(PDFSearchEngine.init(document:))
        documentChanged = true
      } else if searchEngine == nil {
        searchEngine = pdfView.document.map(PDFSearchEngine.init(document:))
        documentChanged = false
      } else {
        documentChanged = false
      }
      configurePageOverlayViewProvider(in: pdfView, forceRewire: documentChanged)

      self.proxy = proxy
      self.relay = PDFViewProxyRelay(
        pdfView: pdfView,
        pageBindings: pageBindings,
        searchBindings: searchBindings,
        searchBindingDriver: searchBindingDriver,
        searchEngine: searchEngine
      )
      synchronizeBindings(in: pdfView)
    }

    func detach() {
      cancelDeferredBindingPublications()
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
      bindingPublicationTiming = .immediate
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
          self?.publishPageState(in: pdfView)
        }
      }
      .store(in: &publishers)

      NotificationCenter.default.publisher(
        for: Notification.Name.PDFViewScaleChanged,
        object: pdfView
      )
      .sink { [weak self] _ in
        MainActor.assumeIsolated {
          self?.publishPageState(in: pdfView)
        }
      }
      .store(in: &publishers)

      #if canImport(UIKit)
        NotificationCenter.default.publisher(
          for: Notification.Name.PDFViewVisiblePagesChanged,
          object: pdfView
        )
        .sink { [weak self] _ in
          MainActor.assumeIsolated {
            // UIKit continuous-mode navigation can settle visible pages later than the
            // initial command dispatch. Listen to visible-page changes so SwiftUI page
            // bindings stay attached to PDFView's actual settled page; otherwise the
            // preview toolbar can remain disabled or show a stale page number.
            self?.publishPageState(in: pdfView)
          }
        }
        .store(in: &publishers)
      #endif
    }

    private func removePublishers() {
      publishers.removeAll()
    }

    private func publishPageState(in pdfView: PDFView) {
      switch bindingPublicationTiming {
      case .immediate:
        pdfView.publishState(pageBindings)
      case .nextMainActorTurn:
        guard deferredBindingSynchronizationTask == nil else { return }
        deferredPagePublicationTask?.cancel()
        deferredPagePublicationTask = Task { @MainActor [weak self, weak pdfView] in
          await Task.yield()
          guard
            !Task.isCancelled,
            let self,
            let pdfView,
            self.pdfView === pdfView
          else {
            return
          }
          self.deferredPagePublicationTask = nil
          pdfView.publishState(self.pageBindings)
        }
      }
    }

    private func synchronizeBindings(in pdfView: PDFView) {
      switch bindingPublicationTiming {
      case .immediate:
        pdfView.publishState(pageBindings)
        refreshSearchBindings(in: pdfView)
      case .nextMainActorTurn:
        deferredPagePublicationTask?.cancel()
        deferredPagePublicationTask = nil
        deferredBindingSynchronizationTask?.cancel()
        deferredBindingSynchronizationTask = Task {
          @MainActor [weak self, weak pdfView] in
          await Task.yield()
          guard
            !Task.isCancelled,
            let self,
            let pdfView,
            self.pdfView === pdfView
          else {
            return
          }
          self.deferredBindingSynchronizationTask = nil
          pdfView.publishState(self.pageBindings)
          self.refreshSearchBindings(in: pdfView)
        }
      }
    }

    private func cancelDeferredBindingPublications() {
      deferredPagePublicationTask?.cancel()
      deferredPagePublicationTask = nil
      deferredBindingSynchronizationTask?.cancel()
      deferredBindingSynchronizationTask = nil
    }

    private func refreshSearchBindings(in pdfView: PDFView) {
      guard let searchEngine else {
        return
      }

      guard
        searchEngine.performFind(
          query: searchBindings.query?.wrappedValue ?? "",
          options: searchBindings.options?.wrappedValue ?? []
        )
      else {
        return
      }

      pdfView.setCurrentSelection(nil, animate: false)
      searchBindingDriver.publish(searchEngine.state, searchBindings: searchBindings)
    }
  }
}
