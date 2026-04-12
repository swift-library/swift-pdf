import PDFKit
import SwiftUI

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
}
