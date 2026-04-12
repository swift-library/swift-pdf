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

private extension CGFloat {
  func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
    Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
  }
}

extension PDFView {
  func publishCurrentPage(_ pageBindings: PDFPageBindings) {
    let currentPage = currentPageIndex
    pageBindings.currentPage?.setIfChanged(currentPage)
  }

  func publishPageCount(_ pageBindings: PDFPageBindings) {
    let currentPageCount = document?.pageCount ?? 0
    pageBindings.pageCount?.setIfChanged(currentPageCount)
  }

  func publishScaleFactor(_ pageBindings: PDFPageBindings) {
    let currentScaleFactor = scaleFactor
    pageBindings.scaleFactor?.setIfChanged(currentScaleFactor)
  }

  func publishState(_ pageBindings: PDFPageBindings) {
    publishPageCount(pageBindings)
    publishCurrentPage(pageBindings)
    publishScaleFactor(pageBindings)
  }

  func goToPage(at pageIndex: Int) {
    let pageCount = document?.pageCount ?? 0
    guard pageCount > 0 else {
      return
    }

    let destinationIndex = pageIndex.clamped(to: pageCount)
    let currentPageIndex = self.currentPageIndex
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

  func goToSelection(_ selection: PDFSelection) {
    setCurrentSelection(selection, animate: true)
    go(to: selection)
  }

  func setScaleFactor(_ scaleFactor: CGFloat) {
    let resolvedScaleFactor: CGFloat
    if minScaleFactor > 0, maxScaleFactor >= minScaleFactor {
      resolvedScaleFactor = scaleFactor.clamped(to: minScaleFactor...maxScaleFactor)
    } else {
      resolvedScaleFactor = scaleFactor
    }

    guard self.scaleFactor != resolvedScaleFactor else {
      return
    }

    self.scaleFactor = resolvedScaleFactor
  }

  func destination(at pageIndex: Int) -> PDFDestination? {
    let pageCount = document?.pageCount ?? 0
    guard pageCount > 0 else {
      return nil
    }

    let destinationIndex = pageIndex.clamped(to: pageCount)
    guard destinationIndex != currentPageIndex,
      let page = document?.page(at: destinationIndex)
    else {
      return nil
    }

    let pageBounds = page.bounds(for: displayBox)
    let topLeading = CGPoint(x: pageBounds.minX, y: pageBounds.maxY)
    return PDFDestination(page: page, at: topLeading)
  }

  var currentPageIndex: Int {
    guard let document = document,
      document.pageCount > 0,
      let currentPage = currentPage
    else {
      return 0
    }

    return document.index(for: currentPage).clamped(to: document.pageCount)
  }
}
