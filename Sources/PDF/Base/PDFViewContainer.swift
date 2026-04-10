import PDFKit
import SwiftUI

@MainActor
public struct PDFViewContainer {
  private let source: PDFDocumentSource

  @Environment(\.viewConfiguration) private var configuration
  @Environment(\.displayMode) private var displayMode
  @Environment(\.displayDirection) private var displayDirection
  @Environment(\.autoScales) private var autoScales
  @Environment(\.isInMarkupMode) private var isInMarkupMode
  @Environment(\.pageIndexBinding) private var pageIndexBinding
  @Environment(\.pageCountBinding) private var pageCountBinding
  @Environment(\.searchQueryBinding) private var searchQueryBinding
  @Environment(\.searchSelectionBinding) private var searchSelectionBinding
  @Environment(\.searchResultCountBinding) private var searchResultCountBinding
  @Environment(\.searchOptionsBinding) private var searchOptionsBinding
  @Environment(\.searchResultsBinding) private var searchResultsBinding
  @Environment(\.pageOverlayContentProvider) private var overlayContentProvider
  @Environment(\.pageOverlayRelease) private var overlayRelease

  private let configurationResolver = PDFViewConfigurationResolver()

  private var effectiveConfiguration: PDFViewConfiguration {
    configurationResolver.resolve(
      base: configuration,
      displayMode: displayMode,
      displayDirection: displayDirection,
      autoScales: autoScales,
      isInMarkupMode: isInMarkupMode
    )
  }

  public init(source: PDFDocumentSource) {
    self.source = source
  }

  func makeConfiguredPDFView(
    coordinator: Coordinator,
    configurePlatformView: (PDFView) -> Void = { _ in }
  ) -> PDFView {
    let pdfView = PDFView()
    effectiveConfiguration.apply(to: pdfView)
    coordinator.updateOverlayCallbacks(
      contentProvider: overlayContentProvider,
      release: overlayRelease
    )
    configurePlatformView(pdfView)
    coordinator.bind(
      pdfView: pdfView,
      initialSource: source,
      pageIndexBinding: pageIndexBinding,
      pageCountBinding: pageCountBinding,
      searchQueryBinding: searchQueryBinding,
      searchSelectionBinding: searchSelectionBinding,
      searchResultCountBinding: searchResultCountBinding,
      searchOptionsBinding: searchOptionsBinding,
      searchResultsBinding: searchResultsBinding
    )
    return pdfView
  }

  func updateConfiguredPDFView(
    _ pdfView: PDFView,
    coordinator: Coordinator,
    configurePlatformView: (PDFView) -> Void = { _ in }
  ) {
    effectiveConfiguration.apply(to: pdfView)
    coordinator.updateOverlayCallbacks(
      contentProvider: overlayContentProvider,
      release: overlayRelease
    )
    configurePlatformView(pdfView)
    coordinator.bind(
      pdfView: pdfView,
      initialSource: source,
      pageIndexBinding: pageIndexBinding,
      pageCountBinding: pageCountBinding,
      searchQueryBinding: searchQueryBinding,
      searchSelectionBinding: searchSelectionBinding,
      searchResultCountBinding: searchResultCountBinding,
      searchOptionsBinding: searchOptionsBinding,
      searchResultsBinding: searchResultsBinding
    )
  }
}

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

    private var pageIndexBinding: Binding<Int>?
    private var pageCountBinding: Binding<Int>?
    private var searchQueryBinding: Binding<String>?
    private var searchSelectionBinding: Binding<Int?>?
    private var searchResultCountBinding: Binding<Int>?
    private var searchOptionsBinding: Binding<PDFSearchOptions>?
    private var searchResultsBinding: Binding<[PDFSearchHit]>?

    var overlayContentProvider: PDFPageOverlayContentProvider = { _ in nil }
    var overlayRelease: PDFPageOverlayRelease = { _ in }
    var overlayHostRegistry = PDFOverlayHostRegistry()

    func bind(
      pdfView: PDFView,
      initialSource: PDFDocumentSource,
      pageIndexBinding: Binding<Int>?,
      pageCountBinding: Binding<Int>?,
      searchQueryBinding: Binding<String>? = nil,
      searchSelectionBinding: Binding<Int?>? = nil,
      searchResultCountBinding: Binding<Int>? = nil,
      searchOptionsBinding: Binding<PDFSearchOptions>? = nil,
      searchResultsBinding: Binding<[PDFSearchHit]>? = nil
    ) {
      let viewChanged = self.pdfView !== pdfView

      if viewChanged {
        removeObservers()
        clearOverlayHosts()
        self.pdfView = pdfView
        installObservers(for: pdfView)
        documentLoader.resetLoadedSourceIdentity()
        pageBindingSynchronizer.reset()
        searchRuntime.reset()
        searchBindingSynchronizer.reset()
      }

      self.pageIndexBinding = pageIndexBinding
      self.pageCountBinding = pageCountBinding
      self.searchQueryBinding = searchQueryBinding
      self.searchSelectionBinding = searchSelectionBinding
      self.searchResultCountBinding = searchResultCountBinding
      self.searchOptionsBinding = searchOptionsBinding
      self.searchResultsBinding = searchResultsBinding

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
      pageIndexBinding = nil
      pageCountBinding = nil
      searchQueryBinding = nil
      searchSelectionBinding = nil
      searchResultCountBinding = nil
      searchOptionsBinding = nil
      searchResultsBinding = nil
      pageBindingSynchronizer.reset()
      searchRuntime.reset()
      searchBindingSynchronizer.reset()
      documentLoader.resetLoadedSourceIdentity()
      clearOverlayHosts()
    }

    func updateOverlayCallbacks(
      contentProvider: @escaping PDFPageOverlayContentProvider,
      release: @escaping PDFPageOverlayRelease
    ) {
      overlayContentProvider = contentProvider
      overlayRelease = release
      refreshOverlayHostsIfNeeded()
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
          pageIndexBinding: pageIndexBinding
        )
      }
      pageBindingSynchronizer.publish(
        on: pdfView,
        pageIndexBinding: pageIndexBinding,
        pageCountBinding: pageCountBinding
      )
    }

    private func refreshSearchBindings() {
      searchBindingSynchronizer.sync(
        on: pdfView,
        runtime: searchRuntime,
        queryBinding: searchQueryBinding,
        selectionBinding: searchSelectionBinding,
        resultCountBinding: searchResultCountBinding,
        optionsBinding: searchOptionsBinding,
        resultsBinding: searchResultsBinding
      )
    }

    private func refreshOverlayHostsIfNeeded() {
      overlayHostRegistry.refresh(
        contentProvider: overlayContent(for:),
        release: releaseOverlay(for:)
      )
    }

    private func clearOverlayHosts() {
      overlayHostRegistry.clear(release: releaseOverlay(for:))
    }

  }
}

@MainActor
private final class PDFDocumentLoader {
  private var loadedSourceIdentity: PDFDocumentSource.Identity?

  var hasLoadedSourceIdentity: Bool {
    loadedSourceIdentity != nil
  }

  func resetLoadedSourceIdentity() {
    loadedSourceIdentity = nil
  }

  func load(source: PDFDocumentSource, forceReload: Bool, into pdfView: PDFView?) -> Bool {
    guard let pdfView else {
      return false
    }

    let sourceIdentity = source.identity
    guard forceReload || loadedSourceIdentity != sourceIdentity else {
      return false
    }

    loadedSourceIdentity = sourceIdentity
    pdfView.document = source.resolveDocument()
    return true
  }
}
