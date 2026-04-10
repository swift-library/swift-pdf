import PDFKit
import SwiftUI

@MainActor
final class PDFPageBindingSynchronizer {
  private var lastAppliedExternalPageIndex: Int?
  private var lastPublishedPageIndex: Int?
  private var lastPublishedPageCount: Int?

  func reset() {
    lastAppliedExternalPageIndex = nil
    lastPublishedPageIndex = nil
    lastPublishedPageCount = nil
  }

  func applyExternalPageIndexIfNeeded(on pdfView: PDFView?, pageIndexBinding: Binding<Int>?) {
    guard let pageIndexBinding else {
      return
    }

    let pageCount = pdfView?.document?.pageCount ?? 0
    let requestedPageIndex = clampedPageIndex(pageIndexBinding.wrappedValue, pageCount: pageCount)

    if pageIndexBinding.wrappedValue != requestedPageIndex {
      pageIndexBinding.wrappedValue = requestedPageIndex
    }

    guard let pdfView, let document = pdfView.document, pageCount > 0 else {
      lastAppliedExternalPageIndex = requestedPageIndex
      return
    }

    if lastAppliedExternalPageIndex == requestedPageIndex
      && lastPublishedPageIndex == requestedPageIndex
    {
      return
    }

    let currentIndex = currentPageIndex(in: pdfView, pageCount: pageCount)
    guard requestedPageIndex != currentIndex else {
      lastAppliedExternalPageIndex = requestedPageIndex
      return
    }

    if let page = document.page(at: requestedPageIndex) {
      lastAppliedExternalPageIndex = requestedPageIndex
      pdfView.go(to: page)
    }
  }

  func publish(
    on pdfView: PDFView?,
    pageIndexBinding: Binding<Int>?,
    pageCountBinding: Binding<Int>?
  ) {
    let pageCount = pdfView?.document?.pageCount ?? 0

    if let pageCountBinding, pageCountBinding.wrappedValue != pageCount {
      pageCountBinding.wrappedValue = pageCount
    }

    lastPublishedPageCount = pageCount

    let currentIndex = currentPageIndex(in: pdfView, pageCount: pageCount)

    if let pageIndexBinding, pageIndexBinding.wrappedValue != currentIndex {
      pageIndexBinding.wrappedValue = currentIndex
    }

    lastPublishedPageIndex = currentIndex
  }

  private func clampedPageIndex(_ index: Int, pageCount: Int) -> Int {
    guard pageCount > 0 else {
      return 0
    }

    return min(max(index, 0), pageCount - 1)
  }

  private func currentPageIndex(in pdfView: PDFView?, pageCount: Int) -> Int {
    guard pageCount > 0,
      let pdfView,
      let document = pdfView.document,
      let currentPage = pdfView.currentPage
    else {
      return 0
    }

    return min(max(0, document.index(for: currentPage)), pageCount - 1)
  }
}
