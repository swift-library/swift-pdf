import PDFKit
import SwiftUI

@MainActor
final class PDFPageStateBindingSynchronizer {
  private var lastAppliedExternalPageIndex: Int?
  private var lastPublishedPageIndex: Int?
  private var lastPublishedPageCount: Int?

  func reset() {
    lastAppliedExternalPageIndex = nil
    lastPublishedPageIndex = nil
    lastPublishedPageCount = nil
  }

  func externalPageToNavigateIfNeeded(on pdfView: PDFView?, pageIndexBinding: Binding<Int>?) -> PDFPage? {
    guard let pageIndexBinding else {
      return nil
    }

    let pageCount = pdfView?.document?.pageCount ?? 0
    let requestedPageIndex = pageIndexBinding.wrappedValue.clamped(to: pageCount)

    if pageIndexBinding.wrappedValue != requestedPageIndex {
      pageIndexBinding.wrappedValue = requestedPageIndex
    }

    guard let pdfView, let document = pdfView.document, pageCount > 0 else {
      lastAppliedExternalPageIndex = requestedPageIndex
      return nil
    }

    if lastAppliedExternalPageIndex == requestedPageIndex
      && lastPublishedPageIndex == requestedPageIndex
    {
      return nil
    }

    let currentIndex = currentPageIndex(in: pdfView, pageCount: pageCount)
    guard requestedPageIndex != currentIndex else {
      lastAppliedExternalPageIndex = requestedPageIndex
      return nil
    }

    if let page = document.page(at: requestedPageIndex) {
      lastAppliedExternalPageIndex = requestedPageIndex
      return page
    }

    return nil
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
  
  private func currentPageIndex(in pdfView: PDFView?, pageCount: Int) -> Int {
    guard pageCount > 0,
      let pdfView,
      let document = pdfView.document,
      let currentPage = pdfView.currentPage
    else {
      return 0
    }

    return document.index(for: currentPage).clamped(to: pageCount)
  }
}

private extension Int {
  func clamped(to pageCount: Int) -> Int {
    guard pageCount > 0 else {
      return 0
    }

    return Swift.min(Swift.max(self, 0), pageCount - 1)
  }
}
