import PDFKit
import SwiftUI

private extension Int {
  func clamped(to pageCount: Int) -> Int {
    guard pageCount > 0 else {
      return 0
    }

    return Swift.min(Swift.max(self, 0), pageCount - 1)
  }
}

extension PDFView {
  func publish(_ pageBindings: PDFPageBindings) {
    let pageCount = document?.pageCount ?? 0
    if let countBinding = pageBindings.pageCount, countBinding.wrappedValue != pageCount {
      countBinding.wrappedValue = pageCount
    }

    let currentIndex = pageIndex
    if let indexBinding = pageBindings.pageIndex, indexBinding.wrappedValue != currentIndex {
      indexBinding.wrappedValue = currentIndex
    }
  }

  func go(to pageIndex: Int) {
    let pageCount = document?.pageCount ?? 0
    guard pageCount > 0 else {
      return
    }

    let destinationIndex = pageIndex.clamped(to: pageCount)
    let currentPageIndex = self.pageIndex
    guard destinationIndex != currentPageIndex else {
      return
    }

    if destinationIndex == currentPageIndex + 1, canGoToNextPage {
      goToNextPage(nil)
      return
    }

    if destinationIndex == currentPageIndex - 1, canGoToPreviousPage {
      goToPreviousPage(nil)
      return
    }

    guard let destination = destination(at: destinationIndex) else {
      return
    }

    go(to: destination)
  }

  func destination(at pageIndex: Int) -> PDFDestination? {
    let pageCount = document?.pageCount ?? 0
    guard pageCount > 0 else {
      return nil
    }

    let destinationIndex = pageIndex.clamped(to: pageCount)
    guard destinationIndex != self.pageIndex,
      let page = document?.page(at: destinationIndex)
    else {
      return nil
    }

    let pageBounds = page.bounds(for: displayBox)
    let topLeading = CGPoint(x: pageBounds.minX, y: pageBounds.maxY)
    return PDFDestination(page: page, at: topLeading)
  }

  var pageIndex: Int {
    guard let document = document,
      document.pageCount > 0,
      let currentPage = currentPage
    else {
      return 0
    }

    return document.index(for: currentPage).clamped(to: document.pageCount)
  }
}
