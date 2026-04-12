import PDFKit
import SwiftUI

@MainActor
public struct PDFViewContainer {
  private let source: PDFDocument.Representation

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

  public init(source: PDFDocument.Representation) {
    self.source = source
  }

  private func configure(
    _ pdfView: PDFView,
    bindingWith coordinator: Coordinator
  ) {
    pdfView.configure(using: resolvedConfiguration)
    coordinator.updatePageOverlayViewCallbacks(pageOverlayViewCallbacks)
    configurePageOverlayViewProvider(pdfView, coordinator: coordinator)
    coordinator.bind(
      pdfView: pdfView,
      source: source,
      pageBindings: pageBindings,
      searchBindings: searchBindings
    )
  }

  func makeConfiguredPDFView(
    coordinator: Coordinator
  ) -> PDFView {
    let pdfView = PDFView()
    configure(pdfView, bindingWith: coordinator)
    return pdfView
  }

  func updateConfiguredPDFView(
    _ pdfView: PDFView,
    coordinator: Coordinator
  ) {
    configure(pdfView, bindingWith: coordinator)
  }

  private var resolvedConfiguration: PDFViewConfiguration {
    PDFViewConfiguration(
      displayMode: displayMode,
      displayDirection: displayDirection,
      autoScales: autoScales,
      isInMarkupMode: isInMarkupMode
    )
  }

  private var pageBindings: PDFPageBindings {
    PDFPageBindings(
      pageIndex: pageIndexBinding,
      pageCount: pageCountBinding
    )
  }

  private var searchBindings: PDFSearchBindings {
    PDFSearchBindings(
      query: searchQueryBinding,
      selection: searchSelectionBinding,
      resultCount: searchResultCountBinding,
      options: searchOptionsBinding,
      results: searchResultsBinding
    )
  }

  private var pageOverlayViewCallbacks: PDFPageOverlayViewCallbacks {
    PDFPageOverlayViewCallbacks(
      contentProvider: overlayContentProvider,
      release: overlayRelease
    )
  }
}
