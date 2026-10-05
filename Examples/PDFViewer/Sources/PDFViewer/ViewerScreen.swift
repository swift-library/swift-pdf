// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
// Copyright (c) 2026 Xudong Xu

import PDF
import PDFKit
import SwiftUI

@MainActor
struct ViewerScreen: View {
  @State private var overlayTelemetry = OverlayTelemetry()

  @State private var currentPage: Int = 0
  @State private var pageCount: Int = 0
  @State private var scaleFactor: CGFloat = 1
  @State private var pageInput: String = "1"
  @State private var searchQuery: String = ""
  @State private var searchResultIndex: Int? = nil
  @State private var searchResultCount: Int = 0
  @State private var isInMarkupMode: Bool = true
  @State private var overlayMode: OverlayMode = .off

  let source: PDFDocument.Representation

  init(source: PDFDocument.Representation) {
    self.source = source
  }

  private var currentPageNumber: Int {
    pageCount > 0 ? currentPage + 1 : 0
  }

  private var pageSummary: String {
    guard pageCount > 0 else {
      return "Page -/-"
    }
    return "Page \(currentPageNumber)/\(pageCount)"
  }

  private var canGoToPreviousPage: Bool {
    pageCount > 0 && currentPage > 0
  }

  private var canGoToNextPage: Bool {
    pageCount > 0 && currentPage < pageCount - 1
  }

  private var overlaySummary: String {
    guard overlayMode != .off else {
      return "Overlay: off"
    }

    let activeCount = overlayTelemetry.activePages.count
    let lastTapped = overlayTelemetry.lastTappedPage ?? "-"
    return
      "Overlay P:\(overlayTelemetry.providedCount) R:\(overlayTelemetry.releasedCount) A:\(activeCount) T:\(overlayTelemetry.tapCount) Last:\(lastTapped)"
  }

  private var searchSummary: String {
    guard searchResultCount > 0 else {
      return "Matches: 0"
    }

    guard let searchResultIndex else {
      return "Matches: \(searchResultCount)"
    }

    return "Matches: \(searchResultIndex + 1)/\(searchResultCount)"
  }

  private var canClearSearch: Bool {
    !(searchResultCount == 0 && searchQuery.isEmpty)
  }

  @ViewBuilder
  private func documentBody() -> some View {
    let base = PDF(source: source)
      .pdf.displayMode(.singlePageContinuous)
      .pdf.displayDirection(.vertical)
      .pdf.isInMarkupMode(isInMarkupMode)
      .pdf.autoScales(true)
      .pdf.currentPage($currentPage)
      .pdf.pageCount($pageCount)
      .pdf.scaleFactor($scaleFactor)
      .pdf.searchQuery($searchQuery)
      .pdf.searchResultIndex($searchResultIndex)
      .pdf.searchResultCount($searchResultCount)

    if overlayMode == .off {
      base
    } else {
      base
        .pdf.overlay { page in
          let pageKey = overlayKey(for: page)
          return makeOverlayContent(for: pageKey, mode: overlayMode)
        }
        .pdf.overlayRelease { page in
          overlayTelemetry.noteReleased(overlayKey(for: page))
        }
    }
  }

  var body: some View {
    PDFViewReader { proxy in
      documentBody()
        .safeAreaInset(edge: .top) {
          ViewerTopToolbar(
            pageSummary: pageSummary,
            overlaySummary: overlaySummary,
            pageInput: $pageInput,
            canGoToPreviousPage: canGoToPreviousPage,
            canGoToNextPage: canGoToNextPage,
            canJumpToPage: pageCount > 0,
            isInMarkupMode: $isInMarkupMode,
            overlayMode: $overlayMode,
            showMarkupWarning: overlayMode != .off && !isInMarkupMode,
            onFirst: proxy.goToFirstPage,
            onPrevious: proxy.goToPreviousPage,
            onNext: proxy.goToNextPage,
            onLast: proxy.goToLastPage,
            onJumpToPage: { jumpToPageFromInput(proxy: proxy) },
            onResetOverlayTelemetry: overlayTelemetry.reset
          )
        }
        .safeAreaInset(edge: .bottom) {
          ViewerBottomToolbar(
            searchQuery: $searchQuery,
            searchResultCount: searchResultCount,
            searchSummary: searchSummary,
            canClearSearch: canClearSearch,
            onPreviousSearch: proxy.goToPreviousSearchResult,
            onNextSearch: proxy.goToNextSearchResult,
            onClearSearch: {
              clearSearch(proxy: proxy)
            }
          )
        }
        .onChange(of: currentPage) { _, _ in
          syncPageInput()
        }
        .onChange(of: pageCount) { _, _ in
          syncPageInput()
        }
        .onChange(of: overlayMode) { _, _ in
          overlayTelemetry.reset()
        }
        .onChange(of: isInMarkupMode) { _, _ in
          overlayTelemetry.reset()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }

  private func jumpToPageFromInput(proxy: PDFViewProxy) {
    guard pageCount > 0,
      let pageNumber = Int(pageInput),
      (1...pageCount).contains(pageNumber)
    else {
      return
    }

    proxy.goToPage(at: pageNumber - 1)
  }

  private func clearSearch(proxy: PDFViewProxy) {
    searchQuery = ""
    proxy.clearSelection()
  }

  private func syncPageInput() {
    pageInput = pageCount == 0 ? "1" : "\(currentPageNumber)"
  }

  private func overlayKey(for page: PDFPage) -> String {
    if let label = page.label, !label.isEmpty {
      return label
    }

    if let document = page.document {
      return "\(document.index(for: page) + 1)"
    }

    return "?"
  }

  @ViewBuilder
  private func makeOverlayContent(for pageKey: String, mode: OverlayMode) -> some View {
    switch mode {
    case .off:
      EmptyView()
    case .badge:
      overlayBadge("Page \(pageKey)", verticalPadding: 6)
        .onAppear {
          overlayTelemetry.noteProvided(pageKey)
        }
    case .interactive:
      overlayBadge("Tap \(pageKey)", verticalPadding: 7)
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onAppear {
          overlayTelemetry.noteProvided(pageKey)
        }
        .onTapGesture {
          overlayTelemetry.noteTapped(pageKey)
        }
    }
  }

  private func overlayBadge(_ label: String, verticalPadding: CGFloat) -> some View {
    Text(label)
      .font(.caption.monospaced().weight(.semibold))
      .foregroundStyle(.white)
      .padding(.horizontal, 10)
      .padding(.vertical, verticalPadding)
      .background(Color.black.opacity(0.78))
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .padding(12)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}
