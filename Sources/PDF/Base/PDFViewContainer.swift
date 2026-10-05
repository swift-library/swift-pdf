// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import PDFKit
import SwiftUI

@MainActor
struct PDFViewContainer {
  private let source: PDFDocument.Representation

  @Environment(\.displayMode) private var displayMode
  @Environment(\.displayDirection) private var displayDirection
  @Environment(\.autoScales) private var autoScales
  @Environment(\.isInMarkupMode) private var isInMarkupMode
  @Environment(\.pdfViewProxy) private var proxy
  @Environment(\.currentPageBinding) private var currentPageBinding
  @Environment(\.pageCountBinding) private var pageCountBinding
  @Environment(\.scaleFactorBinding) private var scaleFactorBinding
  @Environment(\.searchQueryBinding) private var searchQueryBinding
  @Environment(\.searchResultIndexBinding) private var searchResultIndexBinding
  @Environment(\.searchResultCountBinding) private var searchResultCountBinding
  @Environment(\.searchOptionsBinding) private var searchOptionsBinding
  @Environment(\.searchResultsBinding) private var searchResultsBinding
  @Environment(\.pageOverlayContentProvider) private var overlayContentProvider
  @Environment(\.pageOverlayRelease) private var overlayRelease

  init(source: PDFDocument.Representation) {
    self.source = source
  }

  private func configure(
    _ pdfView: PDFView,
    bindingWith coordinator: Coordinator,
    bindingPublicationTiming: PDFBindingPublicationTiming
  ) {
    pdfView.configure(using: resolvedConfiguration)
    coordinator.updatePageOverlayViewCallbacks(pageOverlayViewCallbacks)
    coordinator.bind(
      view: pdfView,
      from: source,
      pageBindings: pageBindings,
      searchBindings: searchBindings,
      proxy: proxy,
      bindingPublicationTiming: bindingPublicationTiming
    )
  }

  func makePDFView(
    bindingWith coordinator: Coordinator,
    bindingPublicationTiming: PDFBindingPublicationTiming = .immediate
  ) -> PDFView {
    let pdfView = PDFView()
    configure(
      pdfView,
      bindingWith: coordinator,
      bindingPublicationTiming: bindingPublicationTiming
    )
    return pdfView
  }

  func updatePDFView(
    _ pdfView: PDFView,
    bindingWith coordinator: Coordinator,
    bindingPublicationTiming: PDFBindingPublicationTiming = .immediate
  ) {
    configure(
      pdfView,
      bindingWith: coordinator,
      bindingPublicationTiming: bindingPublicationTiming
    )
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
      currentPage: currentPageBinding,
      pageCount: pageCountBinding,
      scaleFactor: scaleFactorBinding
    )
  }

  private var searchBindings: PDFSearchBindings {
    PDFSearchBindings(
      query: searchQueryBinding,
      searchResultIndex: searchResultIndexBinding,
      searchResultCount: searchResultCountBinding,
      options: searchOptionsBinding,
      results: searchResultsBinding
    )
  }

  private var pageOverlayViewCallbacks: PDFPageOverlayViewCallbacks {
    PDFPageOverlayViewCallbacks(
      contentProvider: overlayContentProvider?.provider,
      release: overlayRelease?.release
    )
  }
}
